import 'package:flutter/material.dart';
import '../../../models/categoria.dart';
import '../../../core/constants/app_colors.dart';

/// Card de categoria
class CategoriaCard extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CategoriaCard({
    super.key,
    required this.categoria,
    required this.onTap,
    required this.onDelete,
  });

  Color _getColorFromHex(String hexColor) {
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.category;

    // Mapeamento de alguns ícones comuns
    final iconsMap = {
      'local_drink': Icons.local_drink,
      'fastfood': Icons.fastfood,
      'cake': Icons.cake,
      'category': Icons.category,
      'restaurant': Icons.restaurant,
      'coffee': Icons.coffee,
      'icecream': Icons.icecream,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'breakfast_dining': Icons.breakfast_dining,
    };

    return iconsMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final cor = _getColorFromHex(categoria.cor);
    final icone = _getIconData(categoria.icone);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.2),
          child: Icon(icone, color: cor),
        ),
        title: Text(
          categoria.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: categoria.descricao != null
            ? Text(
                categoria.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: onTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
