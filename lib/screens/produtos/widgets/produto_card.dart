import 'package:flutter/material.dart';
import '../../../models/produto.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Card expansível de produto mostrando suas variações
class ProdutoCard extends StatelessWidget {
  final Produto produto;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProdutoCard({
    super.key,
    required this.produto,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            produto.nome[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          produto.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (produto.descricao != null)
              Text(
                produto.descricao!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Custo: ${CurrencyFormatter.format(produto.custoTotal)} • ${produto.variacoes.length} variações',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (produto.temEstoqueZerado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SEM ESTOQUE',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (produto.temEstoqueBaixo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ESTOQUE BAIXO',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.primary,
              onPressed: onTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          if (produto.variacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhuma variação cadastrada',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produto.variacoes.length,
              itemBuilder: (context, index) {
                final variacao = produto.variacoes[index];
                final estoqueBaixo = variacao.estoqueBaixo;
                final estoqueZerado = variacao.estoqueZerado;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.label_outline,
                    size: 20,
                    color: estoqueZerado
                        ? AppColors.error
                        : estoqueBaixo
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  title: Text(
                    variacao.nome,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Preço: ${CurrencyFormatter.format(variacao.precoVenda)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estoqueZerado
                          ? AppColors.error.withOpacity(0.1)
                          : estoqueBaixo
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: estoqueZerado
                              ? AppColors.error
                              : estoqueBaixo
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variacao.quantidadeEstoque}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: estoqueZerado
                                ? AppColors.error
                                : estoqueBaixo
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
