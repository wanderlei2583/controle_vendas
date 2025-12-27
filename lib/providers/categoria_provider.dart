import 'package:flutter/foundation.dart';
import '../models/categoria.dart';
import '../services/database/database_service.dart';

/// Provider para gerenciar o estado das Categorias
class CategoriaProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoriaProvider(this._databaseService) {
    carregarCategorias();
  }

  // Getters
  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _categorias.isEmpty;

  /// Carrega todas as categorias do banco de dados
  Future<void> carregarCategorias() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categorias = await _databaseService.getAllCategorias();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar categorias: $e';
      _categorias = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona uma nova categoria
  Future<bool> adicionarCategoria(Categoria categoria) async {
    try {
      final id = await _databaseService.insertCategoria(categoria);
      final novaCategoria = categoria.copyWith(id: id);
      _categorias.add(novaCategoria);
      _categorias.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar categoria: $e';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza uma categoria existente
  Future<bool> atualizarCategoria(Categoria categoria) async {
    try {
      await _databaseService.updateCategoria(categoria);
      final index = _categorias.indexWhere((c) => c.id == categoria.id);
      if (index != -1) {
        _categorias[index] = categoria;
        _categorias.sort((a, b) => a.nome.compareTo(b.nome));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar categoria: $e';
      notifyListeners();
      return false;
    }
  }

  /// Exclui uma categoria
  /// Retorna false se houver produtos associados
  Future<bool> excluirCategoria(int id) async {
    try {
      await _databaseService.deleteCategoria(id);
      _categorias.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      // Erro pode ser por foreign key constraint (produtos associados)
      if (e.toString().contains('FOREIGN KEY')) {
        _errorMessage = 'Não é possível excluir categoria com produtos associados';
      } else {
        _errorMessage = 'Erro ao excluir categoria: $e';
      }
      notifyListeners();
      return false;
    }
  }

  /// Busca categoria por ID
  Categoria? buscarPorId(int id) {
    try {
      return _categorias.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca categorias por nome
  List<Categoria> buscarPorNome(String query) {
    if (query.isEmpty) return _categorias;

    final queryLower = query.toLowerCase();
    return _categorias
        .where((c) => c.nome.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
