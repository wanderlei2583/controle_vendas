import 'package:flutter/material.dart';
import '../../../models/forma_pagamento.dart';

/// Widget para seleção de forma de pagamento
class PaymentMethodSelector extends StatelessWidget {
  final FormaPagamento formaSelecionada;
  final ValueChanged<FormaPagamento> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.formaSelecionada,
    required this.onChanged,
  });

  IconData _getIcon(FormaPagamento forma) {
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

  String _getLabel(FormaPagamento forma) {
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

  Color _getColor(FormaPagamento forma) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forma de Pagamento',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FormaPagamento.values.map((forma) {
            final selecionado = forma == formaSelecionada;
            final cor = _getColor(forma);

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIcon(forma),
                    size: 18,
                    color: selecionado ? Colors.white : cor,
                  ),
                  const SizedBox(width: 8),
                  Text(_getLabel(forma)),
                ],
              ),
              selected: selecionado,
              onSelected: (selected) {
                if (selected) {
                  onChanged(forma);
                }
              },
              selectedColor: cor,
              labelStyle: TextStyle(
                color: selecionado ? Colors.white : Colors.black87,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
