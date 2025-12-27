import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../models/produto.dart';
import '../../providers/produto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/produto_card.dart';
import 'produto_form_screen.dart';

/// Tela de listagem de produtos
class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({super.key});

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  int? _categoriaFiltroId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProdutoProvider>().carregarProdutos();
      context.read<CategoriaProvider>().carregarCategorias();
    });
  }

  Future<void> _navegarParaFormulario({Produto? produto}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoFormScreen(produto: produto),
      ),
    );

    if (result == true && mounted) {
      context.read<ProdutoProvider>().carregarProdutos();
    }
  }

  Future<void> _confirmarExclusao(Produto produto) async {
    final confirmado = await DeleteConfirmationDialog.show(
      context,
      message: 'Deseja realmente excluir o produto "${produto.nome}" e todas as suas variações?',
    );

    if (confirmado && mounted) {
      final provider = context.read<ProdutoProvider>();
      final sucesso = await provider.excluirProduto(produto.id!);

      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produto excluído com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Erro ao excluir produto',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _mostrarFiltroCategorias() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<CategoriaProvider>(
          builder: (context, categoriaProvider, _) {
            return ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Todas as Categorias'),
                  selected: _categoriaFiltroId == null,
                  onTap: () {
                    setState(() => _categoriaFiltroId = null);
                    context.read<ProdutoProvider>().limparFiltro();
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ...categoriaProvider.categorias.map((categoria) {
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(categoria.nome),
                    selected: _categoriaFiltroId == categoria.id,
                    onTap: () {
                      setState(() => _categoriaFiltroId = categoria.id);
                      context.read<ProdutoProvider>().filtrarPorCategoria(categoria.id);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.produtos,
        actions: [
          IconButton(
            icon: Icon(
              _categoriaFiltroId != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _mostrarFiltroCategorias,
          ),
        ],
      ),
      body: Consumer<ProdutoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(
              message: 'Carregando produtos...',
            );
          }

          final produtos = provider.produtosFiltrados;

          if (produtos.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: _categoriaFiltroId != null
                  ? 'Nenhum produto nesta categoria'
                  : 'Nenhum produto',
              message: _categoriaFiltroId != null
                  ? 'Adicione produtos para esta categoria'
                  : 'Adicione o primeiro produto para começar',
              actionText: 'Adicionar Produto',
              onAction: () => _navegarParaFormulario(),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.carregarProdutos,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];
                return ProdutoCard(
                  produto: produto,
                  onTap: () => _navegarParaFormulario(produto: produto),
                  onDelete: () => _confirmarExclusao(produto),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
