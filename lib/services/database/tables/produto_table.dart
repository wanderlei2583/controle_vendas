import 'package:sqflite/sqflite.dart';
import '../../../models/produto.dart';
import '../database_helper.dart';
import 'variacao_table.dart';

/// Operações CRUD para a tabela de Produtos
class ProdutoTable {
  static const String tableName = DatabaseHelper.tableProdutos;

  /// Insere um novo produto
  static Future<int> insert(Database db, Produto produto) async {
    return await db.insert(tableName, produto.toMap());
  }

  /// Atualiza um produto existente
  static Future<int> update(Database db, Produto produto) async {
    return await db.update(
      tableName,
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  /// Deleta um produto (CASCADE deleta variações automaticamente)
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca produto por ID
  static Future<Produto?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Produto.fromMap(maps.first);
  }

  /// Busca produto por ID com suas variações
  static Future<Produto?> findByIdWithVariacoes(Database db, int id) async {
    final produto = await findById(db, id);
    if (produto == null) return null;

    // Carregar variações do produto
    final variacoes = await VariacaoTable.findByProdutoId(db, id);
    return produto.copyWith(variacoes: variacoes);
  }

  /// Busca todos os produtos
  static Future<List<Produto>> findAll(Database db, {bool apenasAtivos = false}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: apenasAtivos ? 'ativo = 1' : null,
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Produto.fromMap(maps[i]));
  }

  /// Busca todos os produtos com suas variações
  static Future<List<Produto>> findAllWithVariacoes(Database db, {bool apenasAtivos = false}) async {
    final produtos = await findAll(db, apenasAtivos: apenasAtivos);

    for (var produto in produtos) {
      if (produto.id != null) {
        final variacoes = await VariacaoTable.findByProdutoId(db, produto.id!);
        produto.variacoes = variacoes;
      }
    }

    return produtos;
  }

  /// Busca produtos por categoria
  static Future<List<Produto>> findByCategoria(Database db, int categoriaId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'categoria_id = ? AND ativo = 1',
      whereArgs: [categoriaId],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Produto.fromMap(maps[i]));
  }

  /// Busca produtos por categoria com variações
  static Future<List<Produto>> findByCategoriaWithVariacoes(Database db, int categoriaId) async {
    final produtos = await findByCategoria(db, categoriaId);

    for (var produto in produtos) {
      if (produto.id != null) {
        final variacoes = await VariacaoTable.findByProdutoId(db, produto.id!);
        produto.variacoes = variacoes;
      }
    }

    return produtos;
  }

  /// Busca produtos por nome (busca parcial)
  static Future<List<Produto>> searchByName(Database db, String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'nome LIKE ? AND ativo = 1',
      whereArgs: ['%$query%'],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Produto.fromMap(maps[i]));
  }

  /// Ativa/desativa um produto
  static Future<int> toggleAtivo(Database db, int id, bool ativo) async {
    return await db.update(
      tableName,
      {'ativo': ativo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Conta quantos produtos existem
  static Future<int> count(Database db, {bool apenasAtivos = false}) async {
    final where = apenasAtivos ? 'WHERE ativo = 1' : '';
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName $where');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Conta quantos produtos existem por categoria
  static Future<int> countByCategoria(Database db, int categoriaId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE categoria_id = ? AND ativo = 1',
      [categoriaId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
