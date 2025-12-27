import 'package:flutter/foundation.dart';
import '../models/produto.dart';
import '../models/variacao.dart';
import '../services/database/database_service.dart';

/// Provider para gerenciar o estado dos Produtos
class ProdutoProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<Produto> _produtos = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _categoriaFiltroId;

  ProdutoProvider(this._databaseService) {
    carregarProdutos();
  }

  // Getters
  List<Produto> get produtos => _produtos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _produtos.isEmpty;
  int? get categoriaFiltroId => _categoriaFiltroId;

  /// Retorna produtos filtrados por categoria (se houver filtro ativo)
  List<Produto> get produtosFiltrados {
    if (_categoriaFiltroId == null) return _produtos;
    return _produtos.where((p) => p.categoriaId == _categoriaFiltroId).toList();
  }

  /// Carrega todos os produtos com suas variações
  Future<void> carregarProdutos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _produtos = await _databaseService.getAllProdutosWithVariacoes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar produtos: $e';
      _produtos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega produtos de uma categoria específica
  Future<void> carregarProdutosPorCategoria(int categoriaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _produtos = await _databaseService.getProdutosByCategoria(categoriaId);
      _categoriaFiltroId = categoriaId;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar produtos: $e';
      _produtos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define filtro por categoria
  void filtrarPorCategoria(int? categoriaId) {
    _categoriaFiltroId = categoriaId;
    notifyListeners();
  }

  /// Limpa o filtro de categoria
  void limparFiltro() {
    _categoriaFiltroId = null;
    notifyListeners();
  }

  /// Adiciona um novo produto com suas variações
  Future<bool> adicionarProdutoComVariacoes({
    required Produto produto,
    required List<Variacao> variacoes,
  }) async {
    try {
      // 1. Inserir produto
      final produtoId = await _databaseService.insertProduto(produto);
      final novoProduto = produto.copyWith(id: produtoId);

      // 2. Inserir variações
      final novasVariacoes = <Variacao>[];
      for (var variacao in variacoes) {
        final variacaoId = await _databaseService.insertVariacao(
          variacao.copyWith(produtoId: produtoId),
        );
        novasVariacoes.add(variacao.copyWith(id: variacaoId, produtoId: produtoId));
      }

      // 3. Adicionar à lista local
      _produtos.add(novoProduto.copyWith(variacoes: novasVariacoes));
      _produtos.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar produto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza um produto existente
  Future<bool> atualizarProduto(Produto produto) async {
    try {
      await _databaseService.updateProduto(produto);
      final index = _produtos.indexWhere((p) => p.id == produto.id);
      if (index != -1) {
        _produtos[index] = produto.copyWith(variacoes: _produtos[index].variacoes);
        _produtos.sort((a, b) => a.nome.compareTo(b.nome));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar produto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Exclui um produto (CASCADE deleta variações)
  Future<bool> excluirProduto(int id) async {
    try {
      await _databaseService.deleteProduto(id);
      _produtos.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      // Verifica se é erro de constraint (produto com vendas)
      if (e.toString().contains('FOREIGN KEY constraint failed') ||
          e.toString().contains('constraint')) {
        _errorMessage =
            'Este produto não pode ser excluído pois possui vendas registradas.\n\n'
            'Desative o produto ao invés de excluí-lo para manter o histórico.';
      } else {
        _errorMessage = 'Erro ao excluir produto: $e';
      }
      notifyListeners();
      return false;
    }
  }

  /// Adiciona uma variação a um produto existente
  Future<bool> adicionarVariacao(int produtoId, Variacao variacao) async {
    try {
      final variacaoId = await _databaseService.insertVariacao(
        variacao.copyWith(produtoId: produtoId),
      );

      final index = _produtos.indexWhere((p) => p.id == produtoId);
      if (index != -1) {
        final novaVariacao = variacao.copyWith(id: variacaoId, produtoId: produtoId);
        _produtos[index].variacoes.add(novaVariacao);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar variação: $e';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza uma variação existente
  Future<bool> atualizarVariacao(Variacao variacao) async {
    try {
      await _databaseService.updateVariacao(variacao);

      // Encontrar produto e variação na lista local
      for (var produto in _produtos) {
        final index = produto.variacoes.indexWhere((v) => v.id == variacao.id);
        if (index != -1) {
          produto.variacoes[index] = variacao;
          notifyListeners();
          break;
        }
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar variação: $e';
      notifyListeners();
      return false;
    }
  }

  /// Exclui uma variação
  Future<bool> excluirVariacao(int variacaoId, int produtoId) async {
    try {
      await _databaseService.deleteVariacao(variacaoId);

      final index = _produtos.indexWhere((p) => p.id == produtoId);
      if (index != -1) {
        _produtos[index].variacoes.removeWhere((v) => v.id == variacaoId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir variação: $e';
      notifyListeners();
      return false;
    }
  }

  /// Busca produto por ID com suas variações
  Future<Produto?> buscarProdutoComVariacoes(int id) async {
    try {
      return await _databaseService.getProdutoByIdWithVariacoes(id);
    } catch (e) {
      _errorMessage = 'Erro ao buscar produto: $e';
      notifyListeners();
      return null;
    }
  }

  /// Busca produto por ID na lista local
  Produto? buscarPorId(int id) {
    try {
      return _produtos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca produtos por nome
  List<Produto> buscarPorNome(String query) {
    if (query.isEmpty) return produtosFiltrados;

    final queryLower = query.toLowerCase();
    return produtosFiltrados
        .where((p) => p.nome.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Retorna produtos com estoque baixo
  List<Produto> get produtosComEstoqueBaixo {
    return _produtos.where((p) => p.temEstoqueBaixo).toList();
  }

  /// Retorna produtos com estoque zerado
  List<Produto> get produtosComEstoqueZerado {
    return _produtos.where((p) => p.temEstoqueZerado).toList();
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
