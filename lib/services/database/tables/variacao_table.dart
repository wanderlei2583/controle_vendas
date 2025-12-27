import 'package:sqflite/sqflite.dart';
import '../../../models/variacao.dart';
import '../database_helper.dart';

/// Operações CRUD para a tabela de Variações
class VariacaoTable {
  static const String tableName = DatabaseHelper.tableVariacoes;

  /// Insere uma nova variação
  static Future<int> insert(Database db, Variacao variacao) async {
    return await db.insert(tableName, variacao.toMap());
  }

  /// Atualiza uma variação existente
  static Future<int> update(Database db, Variacao variacao) async {
    return await db.update(
      tableName,
      variacao.toMap(),
      where: 'id = ?',
      whereArgs: [variacao.id],
    );
  }

  /// Deleta uma variação
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca variação por ID
  static Future<Variacao?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Variacao.fromMap(maps.first);
  }

  /// Busca todas as variações de um produto
  static Future<List<Variacao>> findByProdutoId(Database db, int produtoId, {bool apenasAtivas = false}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: apenasAtivas ? 'produto_id = ? AND ativo = 1' : 'produto_id = ?',
      whereArgs: [produtoId],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Variacao.fromMap(maps[i]));
  }

  /// Busca todas as variações
  static Future<List<Variacao>> findAll(Database db, {bool apenasAtivas = false}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: apenasAtivas ? 'ativo = 1' : null,
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Variacao.fromMap(maps[i]));
  }

  /// Busca variações com estoque baixo
  static Future<List<Variacao>> findWithEstoqueBaixo(Database db) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName
      WHERE ativo = 1
        AND estoque_minimo IS NOT NULL
        AND quantidade_estoque > 0
        AND quantidade_estoque <= estoque_minimo
      ORDER BY quantidade_estoque ASC
    ''');

    return List.generate(maps.length, (i) => Variacao.fromMap(maps[i]));
  }

  /// Busca variações com estoque zerado
  static Future<List<Variacao>> findWithEstoqueZerado(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'ativo = 1 AND quantidade_estoque <= 0',
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Variacao.fromMap(maps[i]));
  }

  /// Atualiza a quantidade em estoque
  static Future<int> updateEstoque(Database db, int id, int novaQuantidade) async {
    return await db.update(
      tableName,
      {'quantidade_estoque': novaQuantidade},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ativa/desativa uma variação
  static Future<int> toggleAtivo(Database db, int id, bool ativo) async {
    return await db.update(
      tableName,
      {'ativo': ativo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca variações por nome (busca parcial)
  static Future<List<Variacao>> searchByName(Database db, String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'nome LIKE ? AND ativo = 1',
      whereArgs: ['%$query%'],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Variacao.fromMap(maps[i]));
  }

  /// Conta quantas variações existem para um produto
  static Future<int> countByProduto(Database db, int produtoId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE produto_id = ?',
      [produtoId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Conta total de variações
  static Future<int> count(Database db, {bool apenasAtivas = false}) async {
    final where = apenasAtivas ? 'WHERE ativo = 1' : '';
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName $where');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Verifica se há estoque disponível
  static Future<bool> hasEstoqueDisponivel(Database db, int id, int quantidadeNecessaria) async {
    final variacao = await findById(db, id);
    if (variacao == null) return false;
    return variacao.quantidadeEstoque >= quantidadeNecessaria;
  }
}
