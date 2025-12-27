import 'package:sqflite/sqflite.dart';
import '../../../models/categoria.dart';
import '../database_helper.dart';

/// Operações CRUD para a tabela de Categorias
class CategoriaTable {
  static const String tableName = DatabaseHelper.tableCategorias;

  /// Insere uma nova categoria
  static Future<int> insert(Database db, Categoria categoria) async {
    return await db.insert(tableName, categoria.toMap());
  }

  /// Atualiza uma categoria existente
  static Future<int> update(Database db, Categoria categoria) async {
    return await db.update(
      tableName,
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  /// Deleta uma categoria
  /// Retorna erro se houver produtos associados (FOREIGN KEY RESTRICT)
  static Future<int> delete(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca categoria por ID
  static Future<Categoria?> findById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Categoria.fromMap(maps.first);
  }

  /// Busca todas as categorias
  static Future<List<Categoria>> findAll(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Categoria.fromMap(maps[i]));
  }

  /// Busca categorias por nome (busca parcial)
  static Future<List<Categoria>> searchByName(Database db, String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'nome LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) => Categoria.fromMap(maps[i]));
  }

  /// Verifica se existe categoria com o nome especificado
  static Future<bool> existsByName(Database db, String nome, {int? excludeId}) async {
    String where = 'LOWER(nome) = LOWER(?)';
    List<dynamic> whereArgs = [nome];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );

    return maps.isNotEmpty;
  }

  /// Conta quantas categorias existem
  static Future<int> count(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
