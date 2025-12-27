import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/movimentacao_estoque.dart';
import '../../providers/estoque_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

/// Tela de histórico de movimentações de estoque
class MovimentacaoEstoqueScreen extends StatefulWidget {
  final int variacaoId;

  const MovimentacaoEstoqueScreen({
    super.key,
    required this.variacaoId,
  });

  @override
  State<MovimentacaoEstoqueScreen> createState() =>
      _MovimentacaoEstoqueScreenState();
}

class _MovimentacaoEstoqueScreenState extends State<MovimentacaoEstoqueScreen> {
  List<MovimentacaoEstoque> _movimentacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
  }

  Future<void> _carregarMovimentacoes() async {
    setState(() => _isLoading = true);
    final provider = context.read<EstoqueProvider>();
    final movimentacoes = await provider.carregarMovimentacoesPorVariacao(
      widget.variacaoId,
    );

    if (mounted) {
      setState(() {
        _movimentacoes = movimentacoes;
        _isLoading = false;
      });
    }
  }

  IconData _getTipoIcon(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return Icons.arrow_downward;
      case TipoMovimentacao.saida:
        return Icons.arrow_upward;
      case TipoMovimentacao.ajuste:
        return Icons.sync_alt;
      case TipoMovimentacao.vendaAutomatica:
        return Icons.shopping_cart;
    }
  }

  Color _getTipoColor(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return Colors.green;
      case TipoMovimentacao.saida:
        return Colors.red;
      case TipoMovimentacao.ajuste:
        return Colors.blue;
      case TipoMovimentacao.vendaAutomatica:
        return Colors.purple;
    }
  }

  String _getTipoLabel(TipoMovimentacao tipo) {
    switch (tipo) {
      case TipoMovimentacao.entrada:
        return 'Entrada';
      case TipoMovimentacao.saida:
        return 'Saída';
      case TipoMovimentacao.ajuste:
        return 'Ajuste';
      case TipoMovimentacao.vendaAutomatica:
        return 'Venda';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Histórico de Movimentações',
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Carregando...')
          : _movimentacoes.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'Sem movimentações',
                  message: 'Nenhuma movimentação registrada para este item',
                )
              : RefreshIndicator(
                  onRefresh: _carregarMovimentacoes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _movimentacoes.length,
                    itemBuilder: (context, index) {
                      final mov = _movimentacoes[index];
                      final tipo = mov.tipo;
                      final cor = _getTipoColor(tipo);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getTipoIcon(tipo),
                              color: cor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getTipoLabel(tipo),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tipo == TipoMovimentacao.entrada
                                    ? '+${mov.quantidade}'
                                    : '-${mov.quantidade}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatDateTime(
                                  mov.dataMovimentacao,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${mov.quantidadeAnterior}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  Text(
                                    '${mov.quantidadePosterior}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              if (mov.observacao != null &&
                                  mov.observacao!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mov.observacao!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (mov.vendaId != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.purple.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Venda #${mov.vendaId}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
