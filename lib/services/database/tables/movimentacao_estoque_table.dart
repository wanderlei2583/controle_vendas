import 'package:sqflite/sqflite.dart';
import '../../../models/movimentacao_estoque.dart';
import '../database_helper.dart';

/// Operações CRUD para a tabela de Movimentações de Estoque
class MovimentacaoEstoqueTable {
  static const String tableName = DatabaseHelper.tableMovimentacoesEstoque;

  /// Insere uma nova movimentação
  static Future<int> insert(Database db, MovimentacaoEstoque movimentacao) async {
    return await db.insert(tableName, movimentacao.toMap());
  }

  /// Insere múltiplas movimentações de uma vez
  static Future<void> insertBatch(Database db, List<MovimentacaoEstoque> movimentacoes) async {
    final batch = db.batch();
    for (var movimentacao in movimentacoes) {
      batch.insert(tableName, movimentacao.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Atualiza uma movimentação
  static Future<int> update(Database db, MovimentacaoEstoque movimentacao) async {
    return await db.update(
      tableName,
      movimentacao.toMap(),
      where: 'id = ?',
      whereArgs: [movimentacao.id],
    );
  }

  /// Deleta uma movimentação
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca movimentação por ID
  static Future<MovimentacaoEstoque?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return MovimentacaoEstoque.fromMap(maps.first);
  }

  /// Busca todas as movimentações
  static Future<List<MovimentacaoEstoque>> findAll(
    Database db, {
    int? limit,
    int? offset,
  }) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data_movimentacao DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => MovimentacaoEstoque.fromMap(maps[i]));
  }

  /// Busca movimentações por variação
  static Future<List<MovimentacaoEstoque>> findByVariacaoId(
    Database db,
    int variacaoId, {
    int? limit,
  }) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'variacao_id = ?',
      whereArgs: [variacaoId],
      orderBy: 'data_movimentacao DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => MovimentacaoEstoque.fromMap(maps[i]));
  }

  /// Busca movimentações por período
  static Future<List<MovimentacaoEstoque>> findByPeriodo(
    Database db,
    DateTime inicio,
    DateTime fim, {
    int? variacaoId,
    TipoMovimentacao? tipo,
  }) async {
    String where = 'data_movimentacao >= ? AND data_movimentacao <= ?';
    List<dynamic> whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];

    if (variacaoId != null) {
      where += ' AND variacao_id = ?';
      whereArgs.add(variacaoId);
    }

    if (tipo != null) {
      where += ' AND tipo = ?';
      whereArgs.add(tipo.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'data_movimentacao DESC',
    );

    return List.generate(maps.length, (i) => MovimentacaoEstoque.fromMap(maps[i]));
  }

  /// Busca movimentações por tipo
  static Future<List<MovimentacaoEstoque>> findByTipo(
    Database db,
    TipoMovimentacao tipo,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'tipo = ?',
      whereArgs: [tipo.name],
      orderBy: 'data_movimentacao DESC',
    );

    return List.generate(maps.length, (i) => MovimentacaoEstoque.fromMap(maps[i]));
  }

  /// Busca movimentações de uma venda específica
  static Future<List<MovimentacaoEstoque>> findByVendaId(Database db, int vendaId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'venda_id = ?',
      whereArgs: [vendaId],
      orderBy: 'data_movimentacao DESC',
    );

    return List.generate(maps.length, (i) => MovimentacaoEstoque.fromMap(maps[i]));
  }

  /// Obtém histórico completo de movimentações com informações das variações
  static Future<List<Map<String, dynamic>>> obterHistoricoCompleto(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
    int? variacaoId,
    int? limit,
  }) async {
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      where += ' AND m.data_movimentacao >= ? AND m.data_movimentacao <= ?';
      whereArgs.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    if (variacaoId != null) {
      where += ' AND m.variacao_id = ?';
      whereArgs.add(variacaoId);
    }

    String limitClause = limit != null ? 'LIMIT $limit' : '';

    final result = await db.rawQuery('''
      SELECT
        m.*,
        var.nome as variacao_nome,
        p.nome as produto_nome
      FROM $tableName m
      JOIN ${DatabaseHelper.tableVariacoes} var ON m.variacao_id = var.id
      JOIN ${DatabaseHelper.tableProdutos} p ON var.produto_id = p.id
      WHERE $where
      ORDER BY m.data_movimentacao DESC
      $limitClause
    ''', whereArgs);

    return result;
  }

  /// Calcula total de entradas por período
  static Future<int> calcularTotalEntradas(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
    int? variacaoId,
  }) async {
    String where = 'tipo = ?';
    List<dynamic> whereArgs = [TipoMovimentacao.entrada.name];

    if (inicio != null && fim != null) {
      where += ' AND data_movimentacao >= ? AND data_movimentacao <= ?';
      whereArgs.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    if (variacaoId != null) {
      where += ' AND variacao_id = ?';
      whereArgs.add(variacaoId);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantidade), 0) as total FROM $tableName WHERE $where',
      whereArgs,
    );

    return (result.first['total'] as num).toInt();
  }

  /// Calcula total de saídas por período
  static Future<int> calcularTotalSaidas(
    Database db, {
    DateTime? inicio,
    DateTime? fim,
    int? variacaoId,
  }) async {
    String where = "(tipo = ? OR tipo = ?)";
    List<dynamic> whereArgs = [
      TipoMovimentacao.saida.name,
      TipoMovimentacao.vendaAutomatica.name,
    ];

    if (inicio != null && fim != null) {
      where += ' AND data_movimentacao >= ? AND data_movimentacao <= ?';
      whereArgs.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    if (variacaoId != null) {
      where += ' AND variacao_id = ?';
      whereArgs.add(variacaoId);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantidade), 0) as total FROM $tableName WHERE $where',
      whereArgs,
    );

    return (result.first['total'] as num).toInt();
  }

  /// Conta movimentações
  static Future<int> count(Database db, {TipoMovimentacao? tipo}) async {
    String where = tipo != null ? 'WHERE tipo = ?' : '';
    List<dynamic> whereArgs = tipo != null ? [tipo.name] : [];

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName $where',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
