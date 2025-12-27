import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/produto.dart';
import '../../models/variacao.dart';
import '../../models/categoria.dart';
import '../../providers/produto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'widgets/variacao_form_dialog.dart';
import 'widgets/variacao_list_item.dart';

/// Tela de formulário de produto (adicionar/editar)
class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _custoTotalController = TextEditingController();

  Categoria? _categoriaSelecionada;
  List<Variacao> _variacoes = [];
  bool _isLoading = false;
  bool _isEdicao = false;

  @override
  void initState() {
    super.initState();
    _isEdicao = widget.produto != null;

    if (_isEdicao) {
      _nomeController.text = widget.produto!.nome;
      _descricaoController.text = widget.produto!.descricao ?? '';
      _custoTotalController.text = widget.produto!.custoTotal.toStringAsFixed(2);
      _variacoes = List.from(widget.produto!.variacoes);

      // Buscar categoria selecionada
      Future.microtask(() {
        final categoriaProvider = context.read<CategoriaProvider>();
        _categoriaSelecionada = categoriaProvider.buscarPorId(widget.produto!.categoriaId);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _custoTotalController.dispose();
    super.dispose();
  }

  Future<void> _adicionarVariacao() async {
    final variacao = await showDialog<Variacao>(
      context: context,
      builder: (context) => const VariacaoFormDialog(),
    );

    if (variacao != null) {
      setState(() {
        _variacoes.add(variacao);
      });
    }
  }

  Future<void> _editarVariacao(int index) async {
    final variacaoEditada = await showDialog<Variacao>(
      context: context,
      builder: (context) => VariacaoFormDialog(
        variacao: _variacoes[index],
      ),
    );

    if (variacaoEditada != null) {
      setState(() {
        _variacoes[index] = variacaoEditada;
      });
    }
  }

  void _excluirVariacao(int index) {
    setState(() {
      _variacoes.removeAt(index);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_variacoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma variação'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final custoTotal = CurrencyFormatter.parse(_custoTotalController.text) ?? 0.0;

    final produto = Produto(
      id: widget.produto?.id,
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim(),
      categoriaId: _categoriaSelecionada!.id!,
      custoTotal: custoTotal,
      dataCriacao: widget.produto?.dataCriacao,
    );

    final provider = context.read<ProdutoProvider>();
    bool sucesso;

    if (_isEdicao) {
      // Atualizar produto existente
      sucesso = await provider.atualizarProduto(produto);

      // TODO: Atualizar variações (adicionar, editar, excluir)
      // Por enquanto, apenas atualiza o produto principal
    } else {
      // Criar novo produto com variações
      sucesso = await provider.adicionarProdutoComVariacoes(
        produto: produto,
        variacoes: _variacoes,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (sucesso) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdicao
                  ? 'Produto atualizado com sucesso!'
                  : 'Produto adicionado com sucesso!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Erro ao salvar produto',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEdicao ? 'Editar Produto' : 'Novo Produto',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informações básicas
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nome do Produto',
              controller: _nomeController,
              validator: (value) => Validators.required(value, fieldName: 'Nome'),
              prefixIcon: Icons.inventory_2,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Descrição (opcional)',
              controller: _descricaoController,
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            Consumer<CategoriaProvider>(
              builder: (context, categoriaProvider, _) {
                return DropdownButtonFormField<Categoria>(
                  value: _categoriaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categoriaProvider.categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.nome),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _categoriaSelecionada = value),
                  validator: (value) {
                    if (value == null) return 'Selecione uma categoria';
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            CurrencyTextField(
              label: 'Custo Total do Produto',
              controller: _custoTotalController,
              validator: Validators.currency,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),

            // Variações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variações (${_variacoes.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _adicionarVariacao,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_variacoes.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma variação adicionada',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione variações como sabores, tamanhos, etc.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_variacoes.length, (index) {
                return VariacaoListItem(
                  variacao: _variacoes[index],
                  onEdit: () => _editarVariacao(index),
                  onDelete: () => _excluirVariacao(index),
                );
              }),

            const SizedBox(height: 32),

            // Botão salvar
            CustomButton(
              text: _isEdicao ? 'Atualizar Produto' : 'Adicionar Produto',
              onPressed: _salvar,
              isLoading: _isLoading,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
