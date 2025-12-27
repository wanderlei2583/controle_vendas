import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/venda_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/cart_item_widget.dart';
import 'widgets/produto_selector_dialog.dart';
import 'widgets/payment_method_selector.dart';

/// Tela de criação de nova venda
class NovaVendaScreen extends StatefulWidget {
  const NovaVendaScreen({super.key});

  @override
  State<NovaVendaScreen> createState() => _NovaVendaScreenState();
}

class _NovaVendaScreenState extends State<NovaVendaScreen> {
  final _observacoesController = TextEditingController();
  bool _isFinalizando = false;

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _adicionarProduto() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ProdutoSelectorDialog(),
    );

    if (result != null && mounted) {
      final provider = context.read<VendaProvider>();
      final sucesso = await provider.adicionarAoCarrinho(
        variacao: result['variacao'],
        produto: result['produto'],
        quantidade: result['quantidade'],
      );

      if (!sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao adicionar item'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _finalizarVenda() async {
    final provider = context.read<VendaProvider>();

    if (provider.carrinhoVazio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um produto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Confirmar finalização
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Venda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirma a finalização desta venda?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor Total:'),
                      Text(
                        CurrencyFormatter.format(provider.valorTotalCarrinho),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lucro:'),
                      Text(
                        CurrencyFormatter.format(provider.lucroCarrinho),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.lucroCarrinho >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _isFinalizando = true);

    // Salvar observações
    if (_observacoesController.text.trim().isNotEmpty) {
      provider.setObservacoes(_observacoesController.text.trim());
    }

    final sucesso = await provider.finalizarVenda();

    if (mounted) {
      setState(() => _isFinalizando = false);

      if (sucesso) {
        _observacoesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venda finalizada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Erro ao finalizar venda',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _limparCarrinho() async {
    final provider = context.read<VendaProvider>();
    if (provider.carrinhoVazio) return;

    final confirmado = await DeleteConfirmationDialog.show(
      context,
      title: 'Limpar Carrinho',
      message: 'Deseja remover todos os itens do carrinho?',
    );

    if (confirmado && mounted) {
      provider.limparCarrinho();
      _observacoesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrinho limpo'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nova Venda',
        actions: [
          Consumer<VendaProvider>(
            builder: (context, provider, _) {
              if (provider.carrinhoVazio) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _limparCarrinho,
                tooltip: 'Limpar carrinho',
              );
            },
          ),
        ],
      ),
      body: Consumer<VendaProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Lista de itens no carrinho
              Expanded(
                child: provider.carrinhoVazio
                    ? EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Carrinho vazio',
                        message: 'Adicione produtos para iniciar uma venda',
                        actionText: 'Adicionar Produto',
                        onAction: _adicionarProduto,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: provider.carrinho.length,
                        itemBuilder: (context, index) {
                          final item = provider.carrinho[index];
                          return CartItemWidget(
                            item: item,
                            index: index,
                            onRemove: () => provider.removerDoCarrinho(index),
                            onUpdateQuantity: (novaQuantidade) async {
                              final sucesso = await provider.atualizarQuantidadeItem(
                                index: index,
                                novaQuantidade: novaQuantidade,
                              );
                              if (!sucesso && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.errorMessage ?? 'Erro ao atualizar quantidade',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),

              // Resumo e finalização
              if (!provider.carrinhoVazio)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumo de valores
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Itens (${provider.quantidadeItensCarrinho}):',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(provider.valorTotalCarrinho),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Custo Total:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(provider.custoTotalCarrinho),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Lucro:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(provider.lucroCarrinho),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: provider.lucroCarrinho >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Margem:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${provider.margemLucroCarrinho.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(provider.valorTotalCarrinho),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forma de pagamento
                        PaymentMethodSelector(
                          formaSelecionada: provider.formaPagamentoSelecionada,
                          onChanged: provider.setFormaPagamento,
                        ),
                        const SizedBox(height: 16),

                        // Observações
                        TextField(
                          controller: _observacoesController,
                          decoration: const InputDecoration(
                            labelText: 'Observações (opcional)',
                            hintText: 'Ex: Cliente, anotações...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          enabled: !_isFinalizando,
                        ),
                        const SizedBox(height: 16),

                        // Botão finalizar
                        CustomButton(
                          text: 'Finalizar Venda',
                          onPressed: _finalizarVenda,
                          isLoading: _isFinalizando,
                          icon: Icons.check_circle,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<VendaProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton.extended(
            onPressed: _adicionarProduto,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Produto'),
          );
        },
      ),
    );
  }
}
