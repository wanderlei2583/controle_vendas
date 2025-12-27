import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/variacao.dart';
import '../../models/produto.dart';
import '../../providers/produto_provider.dart';
import '../../providers/estoque_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'movimentacao_estoque_screen.dart';
import 'widgets/estoque_ajuste_dialog.dart';

/// Tela de controle de estoque
class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  String _filtro = 'todos'; // todos, baixo, zerado

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProdutoProvider>().carregarProdutos();
    });
  }

  Future<void> _navegarParaMovimentacoes(Variacao variacao) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovimentacaoEstoqueScreen(
          variacaoId: variacao.id!,
        ),
      ),
    );
  }

  Future<void> _ajustarEstoque(Variacao variacao, Produto produto) async {
    final estoqueProvider = context.read<EstoqueProvider>();

    final novaQuantidade = await showDialog<int>(
      context: context,
      builder: (context) => EstoqueAjusteDialog(
        variacao: variacao,
        produto: produto,
      ),
    );

    if (novaQuantidade != null && mounted) {
      final sucesso = await estoqueProvider.registrarAjuste(
        variacaoId: variacao.id!,
        quantidadeNova: novaQuantidade,
      );

      if (mounted) {
        if (sucesso) {
          await context.read<ProdutoProvider>().carregarProdutos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estoque ajustado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                estoqueProvider.errorMessage ?? 'Erro ao ajustar estoque',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  List<MapEntry<Produto, Variacao>> _getVariacoesFiltradas(
    ProdutoProvider provider,
  ) {
    final List<MapEntry<Produto, Variacao>> lista = [];

    for (var produto in provider.produtos) {
      for (var variacao in produto.variacoes) {
        lista.add(MapEntry(produto, variacao));
      }
    }

    // Aplicar filtro
    switch (_filtro) {
      case 'baixo':
        return lista.where((entry) => entry.value.estoqueBaixo).toList();
      case 'zerado':
        return lista.where((entry) => entry.value.estoqueZerado).toList();
      default:
        return lista;
    }
  }

  Color _getStatusColor(Variacao variacao) {
    if (variacao.estoqueZerado) return Colors.red;
    if (variacao.estoqueBaixo) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(Variacao variacao) {
    if (variacao.estoqueZerado) return 'ZERADO';
    if (variacao.estoqueBaixo) return 'BAIXO';
    return 'OK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Controle de Estoque',
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _filtro != 'todos' ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            initialValue: _filtro,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'baixo',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('Estoque Baixo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zerado',
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Estoque Zerado'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              setState(() => _filtro = value);
            },
          ),
        ],
      ),
      body: Consumer<ProdutoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(
              message: 'Carregando estoque...',
            );
          }

          final variacoes = _getVariacoesFiltradas(provider);

          if (variacoes.isEmpty) {
            return EmptyState(
              icon: Icons.warehouse_outlined,
              title: _filtro == 'todos'
                  ? 'Nenhum produto cadastrado'
                  : _filtro == 'baixo'
                      ? 'Nenhum produto com estoque baixo'
                      : 'Nenhum produto com estoque zerado',
              message: _filtro == 'todos'
                  ? 'Cadastre produtos para controlar o estoque'
                  : 'Tudo certo com o estoque!',
            );
          }

          // Calcular estatísticas
          final totalVariacoes = provider.produtos
              .fold(0, (sum, p) => sum + p.variacoes.length);
          final comEstoqueBaixo = provider.produtosComEstoqueBaixo.length;
          final comEstoqueZerado = provider.produtosComEstoqueZerado.length;

          return Column(
            children: [
              // Card de estatísticas
              if (_filtro == 'todos')
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.inventory_2,
                        'Total',
                        '$totalVariacoes',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.warning,
                        'Baixo',
                        '$comEstoqueBaixo',
                        Colors.orange,
                      ),
                      _buildStatItem(
                        Icons.error,
                        'Zerado',
                        '$comEstoqueZerado',
                        Colors.red,
                      ),
                    ],
                  ),
                ),

              // Lista de variações
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.carregarProdutos,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: variacoes.length,
                    itemBuilder: (context, index) {
                      final entry = variacoes[index];
                      final produto = entry.key;
                      final variacao = entry.value;
                      final statusColor = _getStatusColor(variacao);
                      final statusText = _getStatusText(variacao);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${variacao.quantidadeEstoque}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            produto.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(variacao.nome),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (variacao.estoqueMinimo != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mín: ${variacao.estoqueMinimo}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(variacao.precoVenda),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'ajustar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Ajustar Estoque'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'historico',
                                child: Row(
                                  children: [
                                    Icon(Icons.history),
                                    SizedBox(width: 8),
                                    Text('Histórico'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'ajustar') {
                                _ajustarEstoque(variacao, produto);
                              } else if (value == 'historico') {
                                _navegarParaMovimentacoes(variacao);
                              }
                            },
                          ),
                          onTap: () => _navegarParaMovimentacoes(variacao),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
