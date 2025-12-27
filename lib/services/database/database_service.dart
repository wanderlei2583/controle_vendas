import 'package:sqflite/sqflite.dart';
import '../../models/categoria.dart';
import '../../models/produto.dart';
import '../../models/variacao.dart';
import '../../models/venda.dart';
import '../../models/item_venda.dart';
import '../../models/movimentacao_estoque.dart';
import '../../models/forma_pagamento.dart';
import 'database_helper.dart';
import 'tables/categoria_table.dart';
import 'tables/produto_table.dart';
import 'tables/variacao_table.dart';
import 'tables/venda_table.dart';
import 'tables/item_venda_table.dart';
import 'tables/movimentacao_estoque_table.dart';

/// Serviço principal de acesso ao banco de dados
/// Fachada que encapsula todas as operações CRUD
class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Obtém a instância do banco de dados
  Future<Database> get database => _dbHelper.database;

  // ========== CATEGORIAS ==========

  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await CategoriaTable.insert(db, categoria);
  }

  Future<int> updateCategoria(Categoria categoria) async {
    final db = await database;
    return await CategoriaTable.update(db, categoria);
  }

  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await CategoriaTable.delete(db, id);
  }

  Future<Categoria?> getCategoriaById(int id) async {
    final db = await database;
    return await CategoriaTable.findById(db, id);
  }

  Future<List<Categoria>> getAllCategorias() async {
    final db = await database;
    return await CategoriaTable.findAll(db);
  }

  Future<List<Categoria>> searchCategorias(String query) async {
    final db = await database;
    return await CategoriaTable.searchByName(db, query);
  }

  // ========== PRODUTOS ==========

  Future<int> insertProduto(Produto produto) async {
    final db = await database;
    return await ProdutoTable.insert(db, produto);
  }

  Future<int> updateProduto(Produto produto) async {
    final db = await database;
    return await ProdutoTable.update(db, produto);
  }

  Future<int> deleteProduto(int id) async {
    final db = await database;
    return await ProdutoTable.delete(db, id);
  }

  Future<Produto?> getProdutoById(int id) async {
    final db = await database;
    return await ProdutoTable.findById(db, id);
  }

  Future<Produto?> getProdutoByIdWithVariacoes(int id) async {
    final db = await database;
    return await ProdutoTable.findByIdWithVariacoes(db, id);
  }

  Future<List<Produto>> getAllProdutos({bool apenasAtivos = true}) async {
    final db = await database;
    return await ProdutoTable.findAll(db, apenasAtivos: apenasAtivos);
  }

  Future<List<Produto>> getAllProdutosWithVariacoes({bool apenasAtivos = true}) async {
    final db = await database;
    return await ProdutoTable.findAllWithVariacoes(db, apenasAtivos: apenasAtivos);
  }

  Future<List<Produto>> getProdutosByCategoria(int categoriaId) async {
    final db = await database;
    return await ProdutoTable.findByCategoriaWithVariacoes(db, categoriaId);
  }

  Future<List<Produto>> searchProdutos(String query) async {
    final db = await database;
    return await ProdutoTable.searchByName(db, query);
  }

  // ========== VARIAÇÕES ==========

  Future<int> insertVariacao(Variacao variacao) async {
    final db = await database;
    return await VariacaoTable.insert(db, variacao);
  }

  Future<int> updateVariacao(Variacao variacao) async {
    final db = await database;
    return await VariacaoTable.update(db, variacao);
  }

  Future<int> deleteVariacao(int id) async {
    final db = await database;
    return await VariacaoTable.delete(db, id);
  }

  Future<Variacao?> getVariacaoById(int id) async {
    final db = await database;
    return await VariacaoTable.findById(db, id);
  }

  Future<List<Variacao>> getVariacoesByProdutoId(int produtoId) async {
    final db = await database;
    return await VariacaoTable.findByProdutoId(db, produtoId);
  }

  Future<List<Variacao>> getVariacoesWithEstoqueBaixo() async {
    final db = await database;
    return await VariacaoTable.findWithEstoqueBaixo(db);
  }

  Future<List<Variacao>> getVariacoesWithEstoqueZerado() async {
    final db = await database;
    return await VariacaoTable.findWithEstoqueZerado(db);
  }

  Future<int> updateEstoqueVariacao(int id, int novaQuantidade) async {
    final db = await database;
    return await VariacaoTable.updateEstoque(db, id, novaQuantidade);
  }

  Future<bool> hasEstoqueDisponivel(int variacaoId, int quantidade) async {
    final db = await database;
    return await VariacaoTable.hasEstoqueDisponivel(db, variacaoId, quantidade);
  }

  Future<List<Variacao>> getAllVariacoes() async {
    final db = await database;
    return await VariacaoTable.findAll(db);
  }

  // ========== VENDAS ==========

  Future<int> insertVenda(Venda venda) async {
    final db = await database;
    return await VendaTable.insert(db, venda);
  }

  Future<int> updateVenda(Venda venda) async {
    final db = await database;
    return await VendaTable.update(db, venda);
  }

  Future<int> deleteVenda(int id) async {
    final db = await database;
    return await VendaTable.delete(db, id);
  }

  Future<Venda?> getVendaById(int id) async {
    final db = await database;
    return await VendaTable.findById(db, id);
  }

  Future<Venda?> getVendaByIdWithItens(int id) async {
    final db = await database;
    return await VendaTable.findByIdWithItens(db, id);
  }

  Future<List<Venda>> getAllVendas({int? limit, int? offset}) async {
    final db = await database;
    return await VendaTable.findAll(db, limit: limit, offset: offset);
  }

  Future<List<Venda>> getVendasByPeriodo(DateTime inicio, DateTime fim) async {
    final db = await database;
    return await VendaTable.findByPeriodo(db, inicio, fim);
  }

  Future<List<Venda>> getAllVendasWithItens({int? limit, int? offset}) async {
    final db = await database;
    return await VendaTable.findAllWithItens(db, limit: limit, offset: offset);
  }

  Future<double> calcularTotalVendas({DateTime? inicio, DateTime? fim}) async {
    final db = await database;
    return await VendaTable.calcularTotalVendas(db, inicio: inicio, fim: fim);
  }

  Future<double> calcularTotalLucro({DateTime? inicio, DateTime? fim}) async {
    final db = await database;
    return await VendaTable.calcularTotalLucro(db, inicio: inicio, fim: fim);
  }

  Future<double> calcularTicketMedio({DateTime? inicio, DateTime? fim}) async {
    final db = await database;
    return await VendaTable.calcularTicketMedio(db, inicio: inicio, fim: fim);
  }

  Future<Map<FormaPagamento, double>> agruparVendasPorFormaPagamento({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await database;
    return await VendaTable.agruparPorFormaPagamento(db, inicio: inicio, fim: fim);
  }

  Future<List<Map<String, dynamic>>> getVendasPorDia({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await database;
    return await VendaTable.obterVendasPorDia(db, inicio: inicio, fim: fim);
  }

  Future<List<Map<String, dynamic>>> getVendasPorFormaPagamento({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await database;
    return await VendaTable.obterVendasPorFormaPagamento(db, inicio: inicio, fim: fim);
  }

  // ========== ITENS DE VENDA ==========

  Future<int> insertItemVenda(ItemVenda item) async {
    final db = await database;
    return await ItemVendaTable.insert(db, item);
  }

  Future<void> insertItensVendaBatch(List<ItemVenda> itens) async {
    final db = await database;
    return await ItemVendaTable.insertBatch(db, itens);
  }

  Future<List<ItemVenda>> getItensByVendaId(int vendaId) async {
    final db = await database;
    return await ItemVendaTable.findByVendaId(db, vendaId);
  }

  Future<List<Map<String, dynamic>>> getProdutosMaisVendidos({
    int limite = 10,
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final db = await database;
    return await ItemVendaTable.obterProdutosMaisVendidos(
      db,
      limite: limite,
      inicio: inicio,
      fim: fim,
    );
  }

  // ========== MOVIMENTAÇÕES DE ESTOQUE ==========

  Future<int> insertMovimentacaoEstoque(MovimentacaoEstoque movimentacao) async {
    final db = await database;
    return await MovimentacaoEstoqueTable.insert(db, movimentacao);
  }

  Future<void> insertMovimentacoesEstoqueBatch(List<MovimentacaoEstoque> movimentacoes) async {
    final db = await database;
    return await MovimentacaoEstoqueTable.insertBatch(db, movimentacoes);
  }

  Future<List<MovimentacaoEstoque>> getMovimentacoesByVariacaoId(
    int variacaoId, {
    int? limit,
  }) async {
    final db = await database;
    return await MovimentacaoEstoqueTable.findByVariacaoId(db, variacaoId, limit: limit);
  }

  Future<List<MovimentacaoEstoque>> getMovimentacoesByPeriodo(
    DateTime inicio,
    DateTime fim, {
    int? variacaoId,
    TipoMovimentacao? tipo,
  }) async {
    final db = await database;
    return await MovimentacaoEstoqueTable.findByPeriodo(
      db,
      inicio,
      fim,
      variacaoId: variacaoId,
      tipo: tipo,
    );
  }

  Future<List<Map<String, dynamic>>> getHistoricoMovimentacoes({
    DateTime? inicio,
    DateTime? fim,
    int? variacaoId,
    int? limit,
  }) async {
    final db = await database;
    return await MovimentacaoEstoqueTable.obterHistoricoCompleto(
      db,
      inicio: inicio,
      fim: fim,
      variacaoId: variacaoId,
      limit: limit,
    );
  }

  // ========== TRANSAÇÕES ==========

  /// Executa uma operação em transação
  Future<T> executeTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Finaliza uma venda completa (venda + itens + baixa de estoque) em transação
  Future<int> finalizarVenda({
    required Venda venda,
    required List<ItemVenda> itens,
  }) async {
    return await executeTransaction((txn) async {
      // 1. Inserir venda
      final vendaId = await txn.insert(
        DatabaseHelper.tableVendas,
        venda.toMap(),
      );

      // 2. Inserir itens da venda
      for (var item in itens) {
        await txn.insert(
          DatabaseHelper.tableItensVenda,
          item.copyWith(vendaId: vendaId).toMap(),
        );

        // 3. Baixar estoque
        final variacaoMaps = await txn.query(
          DatabaseHelper.tableVariacoes,
          where: 'id = ?',
          whereArgs: [item.variacaoId],
        );
        if (variacaoMaps.isNotEmpty) {
          final variacao = Variacao.fromMap(variacaoMaps.first);
          final novaQuantidade = variacao.quantidadeEstoque - item.quantidade;
          await txn.update(
            DatabaseHelper.tableVariacoes,
            {'quantidade_estoque': novaQuantidade},
            where: 'id = ?',
            whereArgs: [item.variacaoId],
          );

          // 4. Registrar movimentação de estoque
          final movimentacao = MovimentacaoEstoque(
            variacaoId: item.variacaoId,
            tipo: TipoMovimentacao.vendaAutomatica,
            quantidade: item.quantidade,
            quantidadeAnterior: variacao.quantidadeEstoque,
            quantidadePosterior: novaQuantidade,
            vendaId: vendaId,
            observacao: 'Venda automática #$vendaId',
          );
          await txn.insert(
            DatabaseHelper.tableMovimentacoesEstoque,
            movimentacao.toMap(),
          );
        }
      }

      return vendaId;
    });
  }

  // ========== UTILIDADES ==========

  /// Fecha a conexão com o banco de dados
  Future<void> close() async {
    await _dbHelper.close();
  }

  /// Deleta o banco de dados (útil para testes)
  Future<void> deleteDatabase() async {
    await _dbHelper.deleteDatabase();
  }

  /// Obtém o caminho do banco de dados
  Future<String> getDatabasePath() async {
    return await _dbHelper.getDatabasePath();
  }

  /// Inicializa o banco de dados explicitamente
  Future<void> initialize() async {
    await database;
  }
}
