import 'package:sqflite/sqflite.dart';
import '../../../models/venda.dart';
import '../../../models/forma_pagamento.dart';
import '../database_helper.dart';
import 'item_venda_table.dart';

/// Operações CRUD para a tabela de Vendas
class VendaTable {
  static const String tableName = DatabaseHelper.tableVendas;

  /// Insere uma nova venda
  static Future<int> insert(Database db, Venda venda) async {
    return await db.insert(tableName, venda.toMap());
  }

  /// Atualiza uma venda existente
  static Future<int> update(Database db, Venda venda) async {
    return await db.update(
      tableName,
      venda.toMap(),
      where: 'id = ?',
      whereArgs: [venda.id],
    );
  }

  /// Deleta uma venda (CASCADE deleta itens automaticamente)
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca venda por ID
  static Future<Venda?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Venda.fromMap(maps.first);
  }

  /// Busca venda por ID com seus itens
  static Future<Venda?> findByIdWithItens(Database db, int id) async {
    final venda = await findById(db, id);
    if (venda == null) return null;

    // Carregar itens da venda
    final itens = await ItemVendaTable.findByVendaId(db, id);
    return venda.copyWith(itens: itens);
  }

  /// Busca todas as vendas
  static Future<List<Venda>> findAll(Database db, {int? limit, int? offset}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data_venda DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Venda.fromMap(maps[i]));
  }

  /// Busca vendas por período
  static Future<List<Venda>> findByPeriodo(
    Database db,
    DateTime inicio,
    DateTime fim,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'data_venda >= ? AND data_venda <= ?',
      whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data_venda DESC',
    );

    return List.generate(maps.length, (i) => Venda.fromMap(maps[i]));
  }

  /// Busca todas as vendas com seus itens
  static Future<List<Venda>> findAllWithItens(Database db, {int? limit, int? offset}) async {
    final vendas = await findAll(db, limit: limit, offset: offset);

    for (var venda in vendas) {
      final itens = await ItemVendaTable.findByVendaId(db, venda.id!);
      venda.itens = itens;
    }

    return vendas;
  }

  /// Busca vendas por forma de pagamento
  static Future<List<Venda>> findByFormaPagamento(
    Database db,
    FormaPagamento formaPagamento,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'forma_pagamento = ?',
      whereArgs: [formaPagamento.name],
      orderBy: 'data_venda DESC',
    );

    return List.generate(maps.length, (i) => Venda.fromMap(maps[i]));
  }

  /// Calcula total de vendas por período
  static Future<double> calcularTotalVendas(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(valor_total), 0) as total FROM $tableName $where',
      whereArgs,
    );

    return (result.first['total'] as num).toDouble();
  }

  /// Calcula total de lucro por período
  static Future<double> calcularTotalLucro(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(lucro), 0) as total FROM $tableName $where',
      whereArgs,
    );

    return (result.first['total'] as num).toDouble();
  }

  /// Agrupa vendas por forma de pagamento
  static Future<Map<FormaPagamento, double>> agruparPorFormaPagamento(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT forma_pagamento, SUM(valor_total) as total
      FROM $tableName
      $where
      GROUP BY forma_pagamento
    ''', whereArgs);

    final Map<FormaPagamento, double> map = {};
    for (var row in result) {
      final forma = FormaPagamento.fromString(row['forma_pagamento'] as String);
      final total = (row['total'] as num).toDouble();
      map[forma] = total;
    }

    return map;
  }

  /// Obtém vendas por dia (para gráficos)
  static Future<List<Map<String, dynamic>>> obterVendasPorDia(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT
        DATE(data_venda) as data,
        COUNT(*) as quantidade_vendas,
        SUM(valor_total) as valor_total,
        SUM(lucro) as lucro
      FROM $tableName
      $where
      GROUP BY DATE(data_venda)
      ORDER BY DATE(data_venda)
    ''', whereArgs);

    return result;
  }

  /// Obtém vendas agrupadas por forma de pagamento
  static Future<List<Map<String, dynamic>>> obterVendasPorFormaPagamento(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT
        forma_pagamento,
        COUNT(*) as quantidade_vendas,
        SUM(valor_total) as valor_total
      FROM $tableName
      $where
      GROUP BY forma_pagamento
      ORDER BY valor_total DESC
    ''', whereArgs);

    return result;
  }

  /// Calcula ticket médio por período
  static Future<double> calcularTicketMedio(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(AVG(valor_total), 0) as media FROM $tableName $where',
      whereArgs,
    );

    return (result.first['media'] as num).toDouble();
  }

  /// Conta quantidade de vendas
  static Future<int> count(Database db, {DateTime? inicio, DateTime? fim}) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where = 'WHERE data_venda >= ? AND data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName $where',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
