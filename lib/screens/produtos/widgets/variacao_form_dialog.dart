import 'package:flutter/material.dart';
import '../../../models/variacao.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// Dialog para adicionar/editar variação de produto
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
  final _custoUnitarioController = TextEditingController();

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
    _custoUnitarioController.dispose();
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
      produtoId: widget.variacao?.produtoId ?? 0,
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
      title: Row(
        children: [
          Icon(
            isEdicao ? Icons.edit : Icons.add_circle_outline,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(isEdicao ? 'Editar Variação' : 'Nova Variação'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dica
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exemplo: Chop de Morango, Tamanho P, Sabor Chocolate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nome da Variação / Sabor
              CustomTextField(
                label: 'Nome / Sabor / Tipo',
                hint: 'Ex: Chop de Morango, Tamanho P',
                controller: _nomeController,
                validator: (value) => Validators.required(value, fieldName: 'Nome'),
                prefixIcon: Icons.label,
              ),
              const SizedBox(height: 16),

              // Preço de Venda
              CurrencyTextField(
                label: 'Preço de Venda (Unitário)',
                controller: _precoVendaController,
                validator: Validators.currency,
              ),
              const SizedBox(height: 16),

              // Quantidade em Estoque
              QuantityTextField(
                label: 'Quantidade Inicial em Estoque',
                controller: _quantidadeEstoqueController,
                validator: (value) => Validators.integer(value, min: 0),
              ),
              const SizedBox(height: 8),
              Text(
                'Você pode adicionar mais estoque depois',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              // Estoque Mínimo
              QuantityTextField(
                label: 'Estoque Mínimo (Alerta)',
                controller: _estoqueMinimoController,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O sistema alertará quando atingir este valor',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
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
