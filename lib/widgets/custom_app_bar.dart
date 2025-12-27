import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// AppBar customizada do aplicativo
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: elevation,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// AppBar com aba de busca
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final void Function(String) onSearch;
  final VoidCallback? onClearSearch;
  final bool isSearching;
  final VoidCallback onToggleSearch;
  final List<Widget>? actions;

  const SearchAppBar({
    super.key,
    required this.title,
    required this.searchHint,
    required this.onSearch,
    this.onClearSearch,
    required this.isSearching,
    required this.onToggleSearch,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: isSearching
          ? TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: searchHint,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: onSearch,
            )
          : Text(title),
      actions: [
        if (isSearching && onClearSearch != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClearSearch,
          ),
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: onToggleSearch,
        ),
        if (actions != null && !isSearching) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
