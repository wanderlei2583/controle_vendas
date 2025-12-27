import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/categoria.dart';
import '../../../providers/categoria_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// Dialog para adicionar/editar categoria
class CategoriaFormDialog extends StatefulWidget {
  final Categoria? categoria;

  const CategoriaFormDialog({super.key, this.categoria});

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _corSelecionada = '#2196F3';
  String _iconeSelecionado = 'category';
  bool _isLoading = false;

  // Cores disponíveis
  final List<String> _coresDisponiveis = [
    '#2196F3', // Azul
    '#FF9800', // Laranja
    '#4CAF50', // Verde
    '#F44336', // Vermelho
    '#9C27B0', // Roxo
    '#FF5722', // Deep Orange
    '#00BCD4', // Cyan
    '#FFEB3B', // Amarelo
    '#795548', // Marrom
    '#9E9E9E', // Cinza
  ];

  // Ícones disponíveis
  final Map<String, IconData> _iconesDisponiveis = {
    'category': Icons.category,
    'local_drink': Icons.local_drink,
    'fastfood': Icons.fastfood,
    'cake': Icons.cake,
    'restaurant': Icons.restaurant,
    'coffee': Icons.coffee,
    'icecream': Icons.icecream,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    'breakfast_dining': Icons.breakfast_dining,
  };

  @override
  void initState() {
    super.initState();
    if (widget.categoria != null) {
      _nomeController.text = widget.categoria!.nome;
      _descricaoController.text = widget.categoria!.descricao ?? '';
      _corSelecionada = widget.categoria!.cor;
      _iconeSelecionado = widget.categoria!.icone ?? 'category';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final categoria = Categoria(
      id: widget.categoria?.id,
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim(),
      icone: _iconeSelecionado,
      cor: _corSelecionada,
      dataCriacao: widget.categoria?.dataCriacao,
    );

    final provider = context.read<CategoriaProvider>();
    final sucesso = widget.categoria == null
        ? await provider.adicionarCategoria(categoria)
        : await provider.atualizarCategoria(categoria);

    setState(() => _isLoading = false);

    if (mounted) {
      if (sucesso) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoria == null
                  ? 'Categoria adicionada com sucesso!'
                  : 'Categoria atualizada com sucesso!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Erro ao salvar categoria',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.categoria != null;

    return AlertDialog(
      title: Text(isEdicao ? 'Editar Categoria' : 'Nova Categoria'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Nome',
                controller: _nomeController,
                validator: (value) => Validators.required(value, fieldName: 'Nome'),
                prefixIcon: Icons.label,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Descrição (opcional)',
                controller: _descricaoController,
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              Text(
                'Escolha um ícone:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconesDisponiveis.entries.map((entry) {
                  final isSelected = _iconeSelecionado == entry.key;
                  return InkWell(
                    onTap: _isLoading
                        ? null
                        : () => setState(() => _iconeSelecionado = entry.key),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getColorFromHex(_corSelecionada).withValues(alpha: 0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _getColorFromHex(_corSelecionada)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected
                            ? _getColorFromHex(_corSelecionada)
                            : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Escolha uma cor:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coresDisponiveis.map((cor) {
                  final isSelected = _corSelecionada == cor;
                  return InkWell(
                    onTap: _isLoading
                        ? null
                        : () => setState(() => _corSelecionada = cor),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorFromHex(cor),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelar),
        ),
        CustomButton(
          text: AppStrings.salvar,
          onPressed: _salvar,
          isLoading: _isLoading,
          width: 100,
        ),
      ],
    );
  }
}
