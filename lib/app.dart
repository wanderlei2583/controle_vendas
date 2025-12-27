import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/themes/app_theme.dart';
import 'services/database/database_service.dart';
import 'providers/categoria_provider.dart';
import 'providers/produto_provider.dart';
import 'providers/estoque_provider.dart';
import 'providers/venda_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/home/home_screen.dart';

/// Widget raiz do aplicativo
class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database Service
        Provider.value(value: databaseService),

        // Providers
        ChangeNotifierProvider(
          create: (_) => CategoriaProvider(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProdutoProvider(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => EstoqueProvider(databaseService),
        ),
        ChangeNotifierProxyProvider<EstoqueProvider, VendaProvider>(
          create: (context) => VendaProvider(
            databaseService,
            context.read<EstoqueProvider>(),
          ),
          update: (context, estoqueProvider, vendaProvider) {
            return vendaProvider ?? VendaProvider(databaseService, estoqueProvider);
          },
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(databaseService),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
