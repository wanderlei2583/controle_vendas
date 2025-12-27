import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/venda.dart';
import '../../models/forma_pagamento.dart';
import '../../providers/venda_provider.dart';
import '../../services/pdf/pdf_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

/// Tela de detalhes de uma venda
class VendaDetalhesScreen extends StatefulWidget {
  final int vendaId;

  const VendaDetalhesScreen({
    super.key,
    required this.vendaId,
  });

  @override
  State<VendaDetalhesScreen> createState() => _VendaDetalhesScreenState();
}

class _VendaDetalhesScreenState extends State<VendaDetalhesScreen> {
  Venda? _venda;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarVenda();
  }

  Future<void> _carregarVenda() async {
    setState(() => _isLoading = true);
    final provider = context.read<VendaProvider>();
    final venda = await provider.buscarVendaComItens(widget.vendaId);

    if (mounted) {
      setState(() {
        _venda = venda;
        _isLoading = false;
      });
    }
  }

  Future<void> _gerarPDF() async {
    if (_venda == null) return;

    try {
      await PDFService.gerarReciboPDF(_venda!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF gerado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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

  Color _getFormaPagamentoColor(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return Colors.green;
      case FormaPagamento.debito:
        return Colors.blue;
      case FormaPagamento.credito:
        return Colors.orange;
      case FormaPagamento.pix:
        return Colors.teal;
      case FormaPagamento.transferencia:
        return Colors.indigo;
      case FormaPagamento.outro:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Detalhes da Venda'),
        body: const LoadingIndicator(message: 'Carregando...'),
      );
    }

    if (_venda == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Detalhes da Venda'),
        body: const Center(
          child: Text('Venda não encontrada'),
        ),
      );
    }

    final venda = _venda!;
    final margemLucro = venda.valorTotal > 0
        ? (venda.lucro / venda.valorTotal) * 100
        : 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Venda #${venda.id}',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _gerarPDF,
            tooltip: 'Gerar PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de informações gerais
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Gerais',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Data',
                    DateFormatter.formatDateTime(venda.dataVenda),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    _getFormaPagamentoIcon(venda.formaPagamento),
                    'Forma de Pagamento',
                    _getFormaPagamentoLabel(venda.formaPagamento),
                    valueColor: _getFormaPagamentoColor(venda.formaPagamento),
                  ),
                  if (venda.observacoes != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.note,
                      'Observações',
                      venda.observacoes!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de resumo financeiro
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo Financeiro',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildFinanceRow(
                    'Valor Total',
                    CurrencyFormatter.format(venda.valorTotal),
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildFinanceRow(
                    'Custo Total',
                    CurrencyFormatter.format(venda.custoTotal),
                    Colors.grey[700]!,
                  ),
                  const SizedBox(height: 8),
                  _buildFinanceRow(
                    'Lucro',
                    CurrencyFormatter.format(venda.lucro),
                    venda.lucro >= 0 ? Colors.green : Colors.red,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildFinanceRow(
                    'Margem',
                    '${margemLucro.toStringAsFixed(1)}%',
                    Colors.grey[600]!,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de itens da venda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itens (${venda.itens.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...venda.itens.map((item) {
                    final lucroItem = item.subtotal - (item.custoUnitario * item.quantidade);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Variação #${item.variacaoId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.quantidade}x',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Preço unit: ${CurrencyFormatter.format(item.precoUnitario)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Custo unit: ${CurrencyFormatter.format(item.custoUnitario)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lucro:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(lucroItem),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: lucroItem >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
