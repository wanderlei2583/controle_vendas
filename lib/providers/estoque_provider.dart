import 'package:flutter/foundation.dart';
import '../models/variacao.dart';
import '../models/movimentacao_estoque.dart';
import '../services/database/database_service.dart';

/// Provider para gerenciar o estado do Estoque
class EstoqueProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<MovimentacaoEstoque> _movimentacoes = [];
  bool _isLoading = false;
  String? _errorMessage;

  EstoqueProvider(this._databaseService);

  // Getters
  List<MovimentacaoEstoque> get movimentacoes => _movimentacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Carrega todas as movimentações de estoque
  Future<void> carregarMovimentacoes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Carregar últimas 100 movimentações
      final historico = await _databaseService.getHistoricoMovimentacoes(limit: 100);
      _movimentacoes = historico.map((map) => MovimentacaoEstoque.fromMap(map)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar movimentações: $e';
      _movimentacoes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega movimentações de uma variação específica
  Future<List<MovimentacaoEstoque>> carregarMovimentacoesPorVariacao(
    int variacaoId,
  ) async {
    try {
      return await _databaseService.getMovimentacoesByVariacaoId(variacaoId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar movimentações: $e';
      notifyListeners();
      return [];
    }
  }

  /// Verifica se há estoque disponível para uma variação
  Future<bool> verificarDisponibilidade({
    required int variacaoId,
    required int quantidade,
  }) async {
    try {
      final variacao = await _databaseService.getVariacaoById(variacaoId);
      if (variacao == null) return false;
      return variacao.quantidadeEstoque >= quantidade;
    } catch (e) {
      _errorMessage = 'Erro ao verificar disponibilidade: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registra entrada de estoque (compra, produção, etc)
  Future<bool> registrarEntrada({
    required int variacaoId,
    required int quantidade,
    String? observacao,
  }) async {
    if (quantidade <= 0) {
      _errorMessage = 'Quantidade deve ser maior que zero';
      notifyListeners();
      return false;
    }

    try {
      // Buscar variação atual
      final variacao = await _databaseService.getVariacaoById(variacaoId);
      if (variacao == null) {
        _errorMessage = 'Variação não encontrada';
        notifyListeners();
        return false;
      }

      final quantidadeAnterior = variacao.quantidadeEstoque;
      final quantidadeNova = quantidadeAnterior + quantidade;

      // Atualizar estoque da variação
      await _databaseService.updateVariacao(
        variacao.copyWith(quantidadeEstoque: quantidadeNova),
      );

      // Registrar movimentação
      final movimentacao = MovimentacaoEstoque(
        variacaoId: variacaoId,
        tipo: TipoMovimentacao.entrada,
        quantidade: quantidade,
        quantidadeAnterior: quantidadeAnterior,
        quantidadePosterior: quantidadeNova,
        dataMovimentacao: DateTime.now(),
        observacao: observacao,
      );

      await _databaseService.insertMovimentacaoEstoque(movimentacao);
      await carregarMovimentacoes();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar entrada: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registra saída de estoque (venda, perda, etc)
  Future<bool> registrarSaida({
    required int variacaoId,
    required int quantidade,
    String? observacao,
    int? vendaId,
  }) async {
    if (quantidade <= 0) {
      _errorMessage = 'Quantidade deve ser maior que zero';
      notifyListeners();
      return false;
    }

    try {
      // Buscar variação atual
      final variacao = await _databaseService.getVariacaoById(variacaoId);
      if (variacao == null) {
        _errorMessage = 'Variação não encontrada';
        notifyListeners();
        return false;
      }

      final quantidadeAnterior = variacao.quantidadeEstoque;

      // Verificar disponibilidade
      if (quantidadeAnterior < quantidade) {
        _errorMessage = 'Estoque insuficiente. Disponível: $quantidadeAnterior';
        notifyListeners();
        return false;
      }

      final quantidadeNova = quantidadeAnterior - quantidade;

      // Atualizar estoque da variação
      await _databaseService.updateVariacao(
        variacao.copyWith(quantidadeEstoque: quantidadeNova),
      );

      // Registrar movimentação
      final movimentacao = MovimentacaoEstoque(
        variacaoId: variacaoId,
        tipo: TipoMovimentacao.saida,
        quantidade: quantidade,
        quantidadeAnterior: quantidadeAnterior,
        quantidadePosterior: quantidadeNova,
        dataMovimentacao: DateTime.now(),
        observacao: observacao,
        vendaId: vendaId,
      );

      await _databaseService.insertMovimentacaoEstoque(movimentacao);
      await carregarMovimentacoes();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar saída: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registra ajuste de estoque (inventário, correções)
  Future<bool> registrarAjuste({
    required int variacaoId,
    required int quantidadeNova,
    String? observacao,
  }) async {
    if (quantidadeNova < 0) {
      _errorMessage = 'Quantidade não pode ser negativa';
      notifyListeners();
      return false;
    }

    try {
      // Buscar variação atual
      final variacao = await _databaseService.getVariacaoById(variacaoId);
      if (variacao == null) {
        _errorMessage = 'Variação não encontrada';
        notifyListeners();
        return false;
      }

      final quantidadeAnterior = variacao.quantidadeEstoque;

      // Calcular diferença
      final diferenca = quantidadeNova - quantidadeAnterior;
      if (diferenca == 0) {
        _errorMessage = 'Quantidade não foi alterada';
        notifyListeners();
        return false;
      }

      // Atualizar estoque da variação
      await _databaseService.updateVariacao(
        variacao.copyWith(quantidadeEstoque: quantidadeNova),
      );

      // Registrar movimentação
      final movimentacao = MovimentacaoEstoque(
        variacaoId: variacaoId,
        tipo: TipoMovimentacao.ajuste,
        quantidade: diferenca.abs(),
        quantidadeAnterior: quantidadeAnterior,
        quantidadePosterior: quantidadeNova,
        dataMovimentacao: DateTime.now(),
        observacao: observacao ?? 'Ajuste de inventário',
      );

      await _databaseService.insertMovimentacaoEstoque(movimentacao);
      await carregarMovimentacoes();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar ajuste: $e';
      notifyListeners();
      return false;
    }
  }

  /// Baixa automática de estoque em lote (usado em vendas)
  /// Retorna true se todas as baixas foram realizadas com sucesso
  Future<bool> baixarEstoqueEmLote({
    required List<Map<String, dynamic>> itens,
    required int vendaId,
  }) async {
    try {
      for (var item in itens) {
        final variacaoId = item['variacaoId'] as int;
        final quantidade = item['quantidade'] as int;

        final sucesso = await registrarSaida(
          variacaoId: variacaoId,
          quantidade: quantidade,
          observacao: 'Venda #$vendaId',
          vendaId: vendaId,
        );

        if (!sucesso) {
          return false;
        }
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao baixar estoque em lote: $e';
      notifyListeners();
      return false;
    }
  }

  /// Retorna variações com estoque baixo
  Future<List<Variacao>> getVariacoesComEstoqueBaixo() async {
    try {
      final todasVariacoes = await _databaseService.getAllVariacoes();
      return todasVariacoes.where((v) => v.estoqueBaixo).toList();
    } catch (e) {
      _errorMessage = 'Erro ao buscar estoque baixo: $e';
      notifyListeners();
      return [];
    }
  }

  /// Retorna variações com estoque zerado
  Future<List<Variacao>> getVariacoesComEstoqueZerado() async {
    try {
      final todasVariacoes = await _databaseService.getAllVariacoes();
      return todasVariacoes.where((v) => v.estoqueZerado).toList();
    } catch (e) {
      _errorMessage = 'Erro ao buscar estoque zerado: $e';
      notifyListeners();
      return [];
    }
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
