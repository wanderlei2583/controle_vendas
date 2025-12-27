import 'package:flutter/material.dart';
import '../../../models/variacao.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Item de lista para variação do produto
class VariacaoListItem extends StatelessWidget {
  final Variacao variacao;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VariacaoListItem({
    super.key,
    required this.variacao,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.label, color: AppColors.primary, size: 20),
        ),
        title: Text(
          variacao.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preço: ${CurrencyFormatter.format(variacao.precoVenda)}'),
            Row(
              children: [
                Text('Estoque: ${variacao.quantidadeEstoque}'),
                if (variacao.estoqueMinimo != null) ...[
                  const Text(' • '),
                  Text('Mínimo: ${variacao.estoqueMinimo}'),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.primary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
