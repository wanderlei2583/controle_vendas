import 'package:sqflite/sqflite.dart';
import '../../../models/item_venda.dart';
import '../database_helper.dart';

/// Operações CRUD para a tabela de Itens de Venda
class ItemVendaTable {
  static const String tableName = DatabaseHelper.tableItensVenda;

  /// Insere um novo item de venda
  static Future<int> insert(Database db, ItemVenda item) async {
    return await db.insert(tableName, item.toMap());
  }

  /// Insere múltiplos itens de uma vez
  static Future<void> insertBatch(Database db, List<ItemVenda> itens) async {
    final batch = db.batch();
    for (var item in itens) {
      batch.insert(tableName, item.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Atualiza um item de venda
  static Future<int> update(Database db, ItemVenda item) async {
    return await db.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deleta um item de venda
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca item por ID
  static Future<ItemVenda?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ItemVenda.fromMap(maps.first);
  }

  /// Busca todos os itens de uma venda
  static Future<List<ItemVenda>> findByVendaId(Database db, int vendaId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'venda_id = ?',
      whereArgs: [vendaId],
    );

    return List.generate(maps.length, (i) => ItemVenda.fromMap(maps[i]));
  }

  /// Busca itens por variação (para ver histórico de vendas de um produto)
  static Future<List<ItemVenda>> findByVariacaoId(Database db, int variacaoId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'variacao_id = ?',
      whereArgs: [variacaoId],
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => ItemVenda.fromMap(maps[i]));
  }

  /// Obtém produtos mais vendidos
  static Future<List<Map<String, dynamic>>> obterProdutosMaisVendidos(
    Database db, {
    int limite = 10,
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String joinWhere = '';
    List<dynamic> whereArgs = [];

    if (inicio != null && fim != null) {
      joinWhere = 'AND v.data_venda >= ? AND v.data_venda <= ?';
      whereArgs = [inicio.toIso8601String(), fim.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT
        var.id as variacao_id,
        var.nome as variacao_nome,
        p.nome as produto_nome,
        SUM(iv.quantidade) as total_vendido,
        SUM(iv.subtotal) as receita_total,
        SUM(iv.subtotal - (iv.custo_unitario * iv.quantidade)) as lucro_total
      FROM $tableName iv
      JOIN ${DatabaseHelper.tableVariacoes} var ON iv.variacao_id = var.id
      JOIN ${DatabaseHelper.tableProdutos} p ON var.produto_id = p.id
      JOIN ${DatabaseHelper.tableVendas} v ON iv.venda_id = v.id
      WHERE 1=1 $joinWhere
      GROUP BY var.id
      ORDER BY total_vendido DESC
      LIMIT ?
    ''', [...whereArgs, limite]);

    return result;
  }

  /// Calcula total vendido de uma variação específica
  static Future<int> calcularTotalVendido(
    Database db,
    int variacaoId, {
    DateTime? inicio,
    DateTime? fim,
  }) async {
    String joinWhere = '';
    List<dynamic> whereArgs = [variacaoId];

    if (inicio != null && fim != null) {
      joinWhere = 'AND v.data_venda >= ? AND v.data_venda <= ?';
      whereArgs.addAll([inicio.toIso8601String(), fim.toIso8601String()]);
    }

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(iv.quantidade), 0) as total
      FROM $tableName iv
      JOIN ${DatabaseHelper.tableVendas} v ON iv.venda_id = v.id
      WHERE iv.variacao_id = ? $joinWhere
    ''', whereArgs);

    return (result.first['total'] as num).toInt();
  }

  /// Conta quantidade de itens vendidos
  static Future<int> count(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
