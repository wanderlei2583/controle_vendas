import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton para gerenciar a conexão com o banco de dados SQLite
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Informações do banco de dados
  static const String _databaseName = 'controle_vendas.db';
  static const int _databaseVersion = 1;

  // Nomes das tabelas
  static const String tableCategorias = 'categorias';
  static const String tableProdutos = 'produtos';
  static const String tableVariacoes = 'variacoes';
  static const String tableVendas = 'vendas';
  static const String tableItensVenda = 'itens_venda';
  static const String tableMovimentacoesEstoque = 'movimentacoes_estoque';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Obtém a instância do banco de dados (cria se não existir)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configura o banco de dados (ativa foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Cria as tabelas do banco de dados
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de Categorias
    await db.execute('''
      CREATE TABLE $tableCategorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        icone TEXT,
        cor TEXT NOT NULL,
        data_criacao TEXT NOT NULL
      )
    ''');

    // Tabela de Produtos
    await db.execute('''
      CREATE TABLE $tableProdutos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        categoria_id INTEGER NOT NULL,
        custo_total REAL NOT NULL,
        data_criacao TEXT NOT NULL,
        ativo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (categoria_id) REFERENCES $tableCategorias(id) ON DELETE RESTRICT
      )
    ''');

    // Tabela de Variações (sub-módulos de produtos)
    await db.execute('''
      CREATE TABLE $tableVariacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produto_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        preco_venda REAL NOT NULL,
        quantidade_estoque INTEGER NOT NULL DEFAULT 0,
        estoque_minimo INTEGER,
        ativo INTEGER NOT NULL DEFAULT 1,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (produto_id) REFERENCES $tableProdutos(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Vendas
    await db.execute('''
      CREATE TABLE $tableVendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_venda TEXT NOT NULL,
        valor_total REAL NOT NULL,
        custo_total REAL NOT NULL,
        lucro REAL NOT NULL,
        forma_pagamento TEXT NOT NULL,
        observacoes TEXT
      )
    ''');

    // Tabela de Itens de Venda
    await db.execute('''
      CREATE TABLE $tableItensVenda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venda_id INTEGER NOT NULL,
        variacao_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        preco_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        custo_unitario REAL NOT NULL,
        FOREIGN KEY (venda_id) REFERENCES $tableVendas(id) ON DELETE CASCADE,
        FOREIGN KEY (variacao_id) REFERENCES $tableVariacoes(id) ON DELETE RESTRICT
      )
    ''');

    // Tabela de Movimentações de Estoque
    await db.execute('''
      CREATE TABLE $tableMovimentacoesEstoque (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variacao_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        quantidade_anterior INTEGER NOT NULL,
        quantidade_posterior INTEGER NOT NULL,
        data_movimentacao TEXT NOT NULL,
        observacao TEXT,
        venda_id INTEGER,
        FOREIGN KEY (variacao_id) REFERENCES $tableVariacoes(id) ON DELETE CASCADE,
        FOREIGN KEY (venda_id) REFERENCES $tableVendas(id) ON DELETE SET NULL
      )
    ''');

    // Criar índices para melhorar performance
    await _createIndexes(db);

    // Inserir dados iniciais (categorias padrão)
    await _insertInitialData(db);
  }

  /// Cria índices para melhor performance
  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX idx_produtos_categoria ON $tableProdutos(categoria_id)');
    await db.execute(
        'CREATE INDEX idx_variacoes_produto ON $tableVariacoes(produto_id)');
    await db.execute(
        'CREATE INDEX idx_vendas_data ON $tableVendas(data_venda)');
    await db.execute(
        'CREATE INDEX idx_itens_venda_venda ON $tableItensVenda(venda_id)');
    await db.execute(
        'CREATE INDEX idx_itens_venda_variacao ON $tableItensVenda(variacao_id)');
    await db.execute(
        'CREATE INDEX idx_movimentacoes_variacao ON $tableMovimentacoesEstoque(variacao_id)');
    await db.execute(
        'CREATE INDEX idx_movimentacoes_data ON $tableMovimentacoesEstoque(data_movimentacao)');
  }

  /// Insere dados iniciais
  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Categorias padrão
    await db.insert(tableCategorias, {
      'nome': 'Bebidas',
      'descricao': 'Bebidas em geral',
      'icone': 'local_drink',
      'cor': '#2196F3',
      'data_criacao': now,
    });

    await db.insert(tableCategorias, {
      'nome': 'Lanches',
      'descricao': 'Lanches e petiscos',
      'icone': 'fastfood',
      'cor': '#FF9800',
      'data_criacao': now,
    });

    await db.insert(tableCategorias, {
      'nome': 'Sobremesas',
      'descricao': 'Sobremesas e doces',
      'icone': 'cake',
      'cor': '#E91E63',
      'data_criacao': now,
    });

    await db.insert(tableCategorias, {
      'nome': 'Outros',
      'descricao': 'Outros produtos',
      'icone': 'category',
      'cor': '#9E9E9E',
      'data_criacao': now,
    });
  }

  /// Atualiza o banco de dados para nova versão
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migração de schema quando necessário
    // Por exemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ...');
    // }
  }

  /// Fecha a conexão com o banco de dados
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Deleta o banco de dados (útil para testes ou reset completo)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Obtém o caminho do banco de dados
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }
}
