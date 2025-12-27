import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../models/categoria.dart';
import '../../providers/categoria_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/categoria_card.dart';
import 'widgets/categoria_form_dialog.dart';

/// Tela de listagem de categorias
class CategoriaListScreen extends StatefulWidget {
  const CategoriaListScreen({super.key});

  @override
  State<CategoriaListScreen> createState() => _CategoriaListScreenState();
}

class _CategoriaListScreenState extends State<CategoriaListScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega categorias ao iniciar a tela
    Future.microtask(
      () => context.read<CategoriaProvider>().carregarCategorias(),
    );
  }

  Future<void> _mostrarFormulario({Categoria? categoria}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CategoriaFormDialog(categoria: categoria),
    );

    if (result == true && mounted) {
      context.read<CategoriaProvider>().carregarCategorias();
    }
  }

  Future<void> _confirmarExclusao(Categoria categoria) async {
    final confirmado = await DeleteConfirmationDialog.show(
      context,
      message: 'Deseja realmente excluir a categoria "${categoria.nome}"?',
    );

    if (confirmado && mounted) {
      final provider = context.read<CategoriaProvider>();
      final sucesso = await provider.excluirCategoria(categoria.id!);

      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoria excluída com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Erro ao excluir categoria',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.categorias),
      body: Consumer<CategoriaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(
              message: 'Carregando categorias...',
            );
          }

          if (provider.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria',
              message: 'Adicione a primeira categoria para começar',
              actionText: 'Adicionar Categoria',
              onAction: () => _mostrarFormulario(),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.carregarCategorias,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.categorias.length,
              itemBuilder: (context, index) {
                final categoria = provider.categorias[index];
                return CategoriaCard(
                  categoria: categoria,
                  onTap: () => _mostrarFormulario(categoria: categoria),
                  onDelete: () => _confirmarExclusao(categoria),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
