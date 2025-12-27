import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/venda.dart';
import '../../models/forma_pagamento.dart';
import '../../providers/venda_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'nova_venda_screen.dart';
import 'venda_detalhes_screen.dart';

/// Tela de listagem de vendas
class VendaListScreen extends StatefulWidget {
  const VendaListScreen({super.key});

  @override
  State<VendaListScreen> createState() => _VendaListScreenState();
}

class _VendaListScreenState extends State<VendaListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<VendaProvider>().carregarVendas();
    });
  }

  Future<void> _navegarParaNovaVenda() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NovaVendaScreen(),
      ),
    );
    if (mounted) {
      context.read<VendaProvider>().carregarVendas();
    }
  }

  Future<void> _navegarParaDetalhes(Venda venda) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendaDetalhesScreen(vendaId: venda.id!),
      ),
    );
  }

  Future<void> _confirmarExclusao(Venda venda) async {
    final confirmado = await DeleteConfirmationDialog.show(
      context,
      message: 'Deseja realmente excluir esta venda? Esta ação não pode ser desfeita.\n\nATENÇÃO: O estoque NÃO será restaurado automaticamente.',
    );

    if (confirmado && mounted) {
      final provider = context.read<VendaProvider>();
      final sucesso = await provider.excluirVenda(venda.id!);

      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venda excluída com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Erro ao excluir venda',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _getFormaPagamentoLabel(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return 'Dinheiro';
      case FormaPagamento.debito:
        return 'Débito';
      case FormaPagamento.credito:
        return 'Crédito';
      case FormaPagamento.pix:
        return 'PIX';
      case FormaPagamento.transferencia:
        return 'Transferência';
      case FormaPagamento.outro:
        return 'Outro';
    }
  }

  IconData _getFormaPagamentoIcon(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return Icons.payments;
      case FormaPagamento.debito:
        return Icons.credit_card;
      case FormaPagamento.credito:
        return Icons.credit_card;
      case FormaPagamento.pix:
        return Icons.qr_code;
      case FormaPagamento.transferencia:
        return Icons.account_balance;
      case FormaPagamento.outro:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Vendas',
      ),
      body: Consumer<VendaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(
              message: 'Carregando vendas...',
            );
          }

          final vendas = provider.vendas;

          if (vendas.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Nenhuma venda registrada',
              message: 'Comece a registrar suas vendas',
              actionText: 'Nova Venda',
              onAction: _navegarParaNovaVenda,
            );
          }

          // Agrupar vendas por data
          final vendasAgrupadas = <String, List<Venda>>{};
          for (var venda in vendas) {
            final dataKey = DateFormatter.formatDateOnly(venda.dataVenda);
            vendasAgrupadas.putIfAbsent(dataKey, () => []);
            vendasAgrupadas[dataKey]!.add(venda);
          }

          return RefreshIndicator(
            onRefresh: provider.carregarVendas,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: vendasAgrupadas.length,
              itemBuilder: (context, index) {
                final dataKey = vendasAgrupadas.keys.elementAt(index);
                final vendasDoDia = vendasAgrupadas[dataKey]!;

                // Calcular totais do dia
                final totalDia = vendasDoDia.fold(
                  0.0,
                  (sum, v) => sum + v.valorTotal,
                );
                final lucroDia = vendasDoDia.fold(
                  0.0,
                  (sum, v) => sum + v.lucro,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do dia
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dataKey,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(totalDia),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${CurrencyFormatter.format(lucroDia)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lucroDia >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lista de vendas do dia
                    ...vendasDoDia.map((venda) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getFormaPagamentoIcon(venda.formaPagamento),
                              color: AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormatter.formatTimeOnly(venda.dataVenda),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(venda.valorTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getFormaPagamentoIcon(venda.formaPagamento),
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getFormaPagamentoLabel(venda.formaPagamento),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.trending_up,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    CurrencyFormatter.format(venda.lucro),
                                    style: TextStyle(
                                      color: venda.lucro >= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (venda.observacoes != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  venda.observacoes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'detalhes',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline),
                                    SizedBox(width: 8),
                                    Text('Detalhes'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'detalhes') {
                                _navegarParaDetalhes(venda);
                              } else if (value == 'excluir') {
                                _confirmarExclusao(venda);
                              }
                            },
                          ),
                          onTap: () => _navegarParaDetalhes(venda),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaNovaVenda,
        child: const Icon(Icons.add),
      ),
    );
  }
}
