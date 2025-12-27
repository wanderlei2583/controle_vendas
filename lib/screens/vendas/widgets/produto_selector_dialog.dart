import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/produto.dart';
import '../../../models/variacao.dart';
import '../../../providers/produto_provider.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/empty_state.dart';

/// Dialog para seleção de produto e variação
class ProdutoSelectorDialog extends StatefulWidget {
  const ProdutoSelectorDialog({super.key});

  @override
  State<ProdutoSelectorDialog> createState() => _ProdutoSelectorDialogState();
}

class _ProdutoSelectorDialogState extends State<ProdutoSelectorDialog> {
  Produto? _produtoSelecionado;
  Variacao? _variacaoSelecionada;
  int _quantidade = 1;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_shopping_cart),
                  const SizedBox(width: 12),
                  const Text(
                    'Adicionar Produto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Campo de busca
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar produto',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // Lista de produtos
            Expanded(
              child: Consumer<ProdutoProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const LoadingIndicator(
                      message: 'Carregando produtos...',
                    );
                  }

                  final produtos = _searchQuery.isEmpty
                      ? provider.produtos
                      : provider.buscarPorNome(_searchQuery);

                  if (produtos.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nenhum produto encontrado',
                      message: 'Adicione produtos para começar a vender',
                    );
                  }

                  return ListView.builder(
                    itemCount: produtos.length,
                    itemBuilder: (context, index) {
                      final produto = produtos[index];
                      final selecionado = _produtoSelecionado?.id == produto.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: selecionado ? 4 : 1,
                        color: selecionado
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                        child: ExpansionTile(
                          title: Text(
                            produto.nome,
                            style: TextStyle(
                              fontWeight: selecionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${produto.variacoes.length} variações',
                          ),
                          children: produto.variacoes.map((variacao) {
                            final variacaoSelecionada =
                                _variacaoSelecionada?.id == variacao.id;
                            final temEstoque = variacao.quantidadeEstoque > 0;

                            return ListTile(
                              selected: variacaoSelecionada,
                              enabled: temEstoque,
                              title: Text(variacao.nome),
                              subtitle: Text(
                                '${CurrencyFormatter.format(variacao.precoVenda)} • Estoque: ${variacao.quantidadeEstoque}',
                              ),
                              trailing: temEstoque
                                  ? (variacaoSelecionada
                                      ? const Icon(Icons.check_circle)
                                      : null)
                                  : const Chip(
                                      label: Text(
                                        'Sem estoque',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.red,
                                      labelPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                              onTap: temEstoque
                                  ? () {
                                      setState(() {
                                        _produtoSelecionado = produto;
                                        _variacaoSelecionada = variacao;
                                        _quantidade = 1;
                                      });
                                    }
                                  : null,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Controles de quantidade e botão adicionar
            if (_variacaoSelecionada != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantidade:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantidade > 1
                                    ? () => setState(() => _quantidade--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  '$_quantidade',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _quantidade <
                                        _variacaoSelecionada!
                                            .quantidadeEstoque
                                    ? () => setState(() => _quantidade++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Disponível: ${_variacaoSelecionada!.quantidadeEstoque}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'produto': _produtoSelecionado,
                          'variacao': _variacaoSelecionada,
                          'quantidade': _quantidade,
                        });
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Adicionar ao Carrinho'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
