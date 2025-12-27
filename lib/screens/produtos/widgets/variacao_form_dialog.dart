import 'package:flutter/material.dart';
import '../../../models/variacao.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// Dialog para adicionar/editar variação
class VariacaoFormDialog extends StatefulWidget {
  final Variacao? variacao;

  const VariacaoFormDialog({super.key, this.variacao});

  @override
  State<VariacaoFormDialog> createState() => _VariacaoFormDialogState();
}

class _VariacaoFormDialogState extends State<VariacaoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _quantidadeEstoqueController = TextEditingController();
  final _estoqueMinimoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.variacao != null) {
      _nomeController.text = widget.variacao!.nome;
      _precoVendaController.text = widget.variacao!.precoVenda.toStringAsFixed(2);
      _quantidadeEstoqueController.text = widget.variacao!.quantidadeEstoque.toString();
      if (widget.variacao!.estoqueMinimo != null) {
        _estoqueMinimoController.text = widget.variacao!.estoqueMinimo.toString();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoVendaController.dispose();
    _quantidadeEstoqueController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final precoVenda = CurrencyFormatter.parse(_precoVendaController.text) ?? 0.0;
    final quantidadeEstoque = int.tryParse(_quantidadeEstoqueController.text) ?? 0;
    final estoqueMinimo = _estoqueMinimoController.text.isEmpty
        ? null
        : int.tryParse(_estoqueMinimoController.text);

    final variacao = Variacao(
      id: widget.variacao?.id,
      produtoId: widget.variacao?.produtoId ?? 0, // Será definido ao salvar o produto
      nome: _nomeController.text.trim(),
      precoVenda: precoVenda,
      quantidadeEstoque: quantidadeEstoque,
      estoqueMinimo: estoqueMinimo,
      dataCriacao: widget.variacao?.dataCriacao,
    );

    Navigator.of(context).pop(variacao);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.variacao != null;

    return AlertDialog(
      title: Text(isEdicao ? 'Editar Variação' : 'Nova Variação'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nome da Variação',
                hint: 'Ex: Chop de Vinho, Tamanho P, Sabor Chocolate',
                controller: _nomeController,
                validator: (value) => Validators.required(value, fieldName: 'Nome'),
                prefixIcon: Icons.label,
              ),
              const SizedBox(height: 16),
              CurrencyTextField(
                label: 'Preço de Venda',
                controller: _precoVendaController,
                validator: Validators.currency,
              ),
              const SizedBox(height: 16),
              QuantityTextField(
                label: 'Quantidade em Estoque',
                controller: _quantidadeEstoqueController,
                validator: (value) => Validators.integer(value, min: 0),
              ),
              const SizedBox(height: 16),
              QuantityTextField(
                label: 'Estoque Mínimo (opcional)',
                controller: _estoqueMinimoController,
              ),
              const SizedBox(height: 8),
              const Text(
                'O sistema alertará quando o estoque atingir este valor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancelar),
        ),
        CustomButton(
          text: AppStrings.salvar,
          onPressed: _salvar,
          width: 100,
        ),
      ],
    );
  }
}
