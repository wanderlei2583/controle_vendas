import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/variacao.dart';
import '../../../models/produto.dart';
import '../../../widgets/custom_button.dart';

/// Dialog para ajuste de estoque
class EstoqueAjusteDialog extends StatefulWidget {
  final Variacao variacao;
  final Produto produto;

  const EstoqueAjusteDialog({
    super.key,
    required this.variacao,
    required this.produto,
  });

  @override
  State<EstoqueAjusteDialog> createState() => _EstoqueAjusteDialogState();
}

class _EstoqueAjusteDialogState extends State<EstoqueAjusteDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.variacao.quantidadeEstoque.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementar() {
    final atual = int.tryParse(_controller.text) ?? 0;
    _controller.text = (atual + 1).toString();
  }

  void _decrementar() {
    final atual = int.tryParse(_controller.text) ?? 0;
    if (atual > 0) {
      _controller.text = (atual - 1).toString();
    }
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      final novaQuantidade = int.tryParse(_controller.text);
      if (novaQuantidade != null) {
        Navigator.of(context).pop(novaQuantidade);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantidadeAtual = widget.variacao.quantidadeEstoque;
    final novaQuantidade = int.tryParse(_controller.text) ?? quantidadeAtual;
    final diferenca = novaQuantidade - quantidadeAtual;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajustar Estoque',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.produto.nome} - ${widget.variacao.nome}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Quantidade atual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantidade Atual:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$quantidadeAtual',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Input de nova quantidade
                Row(
                  children: [
                    IconButton(
                      onPressed: _decrementar,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nova Quantidade',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a quantidade';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Quantidade inválida';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      onPressed: _incrementar,
                      icon: const Icon(Icons.add_circle_outline),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Diferença
                if (diferenca != 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: diferenca > 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: diferenca > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          diferenca > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: diferenca > 0 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          diferenca > 0
                              ? '+${diferenca.abs()} (Entrada)'
                              : '-${diferenca.abs()} (Saída)',
                          style: TextStyle(
                            color: diferenca > 0 ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Confirmar',
                        onPressed: diferenca != 0 ? _confirmar : null,
                        icon: Icons.check,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
