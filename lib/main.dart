import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/database/database_service.dart';

void main() async {
  // Garante que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa formatação de datas em português
  await initializeDateFormatting('pt_BR', null);

  // Inicializa o banco de dados
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(MyApp(databaseService: databaseService));
}
