import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

/// Dialog de confirmação
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDanger;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.icon,
    this.isDanger = false,
  });

  /// Mostra o dialog e retorna true se confirmado, false se cancelado
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    IconData? icon,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.error : (confirmColor ?? AppColors.primary);

    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              color: color,
              size: 48,
            )
          : null,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? AppStrings.cancelar),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
          ),
          child: Text(confirmText ?? AppStrings.confirmar),
        ),
      ],
    );
  }
}

/// Dialog de exclusão (atalho para ConfirmationDialog com isDanger=true)
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;

  const DeleteConfirmationDialog({
    super.key,
    this.title = 'Confirmar Exclusão',
    required this.message,
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Confirmar Exclusão',
    required String message,
  }) async {
    return await ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmText: AppStrings.excluir,
      icon: Icons.delete_forever,
      isDanger: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: title,
      message: message,
      confirmText: AppStrings.excluir,
      icon: Icons.delete_forever,
      isDanger: true,
    );
  }
}
