import 'package:flutter/foundation.dart';
import '../models/venda.dart';
import '../models/produto.dart';
import '../models/variacao.dart';
import '../services/database/database_service.dart';

/// Dados para gráfico de vendas por dia
class VendaDia {
  final DateTime data;
  final double valorTotal;
  final double lucro;
  final int quantidadeVendas;

  VendaDia({
    required this.data,
    required this.valorTotal,
    required this.lucro,
    required this.quantidadeVendas,
  });
}

/// Dados de produto mais vendido
class ProdutoRanking {
  final String nomeProduto;
  final String nomeVariacao;
  final int quantidadeVendida;
  final double valorTotal;
  final double lucro;

  ProdutoRanking({
    required this.nomeProduto,
    required this.nomeVariacao,
    required this.quantidadeVendida,
    required this.valorTotal,
    required this.lucro,
  });
}

/// Dados de vendas por forma de pagamento
class VendasPorPagamento {
  final String formaPagamento;
  final int quantidadeVendas;
  final double valorTotal;
  final double percentual;

  VendasPorPagamento({
    required this.formaPagamento,
    required this.quantidadeVendas,
    required this.valorTotal,
    required this.percentual,
  });
}

/// Provider para dashboard e relatórios
class DashboardProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  bool _isLoading = false;
  String? _errorMessage;

  // Estatísticas gerais
  double _totalVendas = 0;
  double _totalLucro = 0;
  double _ticketMedio = 0;
  double _margemLucro = 0;
  int _quantidadeVendas = 0;

  // Estatísticas do dia
  double _vendasDoDia = 0;
  double _lucroDoDia = 0;
  int _vendasDoDiaCount = 0;

  // Dados para gráficos
  List<VendaDia> _vendasPorDia = [];
  List<ProdutoRanking> _produtosMaisVendidos = [];
  List<VendasPorPagamento> _vendasPorPagamento = [];

  // Alertas
  int _estoquesBaixos = 0;
  int _estoquesZerados = 0;

  DashboardProvider(this._databaseService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalVendas => _totalVendas;
  double get totalLucro => _totalLucro;
  double get ticketMedio => _ticketMedio;
  double get margemLucro => _margemLucro;
  int get quantidadeVendas => _quantidadeVendas;

  double get vendasDoDia => _vendasDoDia;
  double get lucroDoDia => _lucroDoDia;
  int get vendasDoDiaCount => _vendasDoDiaCount;

  List<VendaDia> get vendasPorDia => _vendasPorDia;
  List<ProdutoRanking> get produtosMaisVendidos => _produtosMaisVendidos;
  List<VendasPorPagamento> get vendasPorPagamento => _vendasPorPagamento;

  int get estoquesBaixos => _estoquesBaixos;
  int get estoquesZerados => _estoquesZerados;

  /// Carrega todas as estatísticas do dashboard
  Future<void> carregarDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _carregarEstatisticasGerais(),
        _carregarEstatisticasDoDia(),
        _carregarVendasPorDia(diasAtras: 7),
        _carregarProdutosMaisVendidos(limite: 10),
        _carregarVendasPorPagamento(),
        _carregarAlertasEstoque(),
      ]);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega estatísticas gerais (todos os tempos)
  Future<void> _carregarEstatisticasGerais() async {
    _totalVendas = await _databaseService.calcularTotalVendas();
    _totalLucro = await _databaseService.calcularTotalLucro();
    _ticketMedio = await _databaseService.calcularTicketMedio();

    if (_totalVendas > 0) {
      _margemLucro = (_totalLucro / _totalVendas) * 100;
    } else {
      _margemLucro = 0;
    }

    final vendas = await _databaseService.getAllVendas();
    _quantidadeVendas = vendas.length;
  }

  /// Carrega estatísticas do dia atual
  Future<void> _carregarEstatisticasDoDia() async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    _vendasDoDia = await _databaseService.calcularTotalVendas(
      inicio: inicioDia,
      fim: fimDia,
    );
    _lucroDoDia = await _databaseService.calcularTotalLucro(
      inicio: inicioDia,
      fim: fimDia,
    );

    final vendas = await _databaseService.getVendasByPeriodo(inicioDia, fimDia);
    _vendasDoDiaCount = vendas.length;
  }

  /// Carrega vendas agrupadas por dia
  Future<void> _carregarVendasPorDia({int diasAtras = 7}) async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day)
        .subtract(Duration(days: diasAtras - 1));
    final fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    final vendas = await _databaseService.getVendasPorDia(inicio: inicio, fim: fim);

    _vendasPorDia = vendas.map((map) {
      return VendaDia(
        data: DateTime.parse(map['data'] as String),
        valorTotal: (map['valor_total'] as num).toDouble(),
        lucro: (map['lucro'] as num).toDouble(),
        quantidadeVendas: map['quantidade_vendas'] as int,
      );
    }).toList();
  }

  /// Carrega produtos mais vendidos
  Future<void> _carregarProdutosMaisVendidos({int limite = 10}) async {
    final ranking = await _databaseService.getProdutosMaisVendidos(limite: limite);

    _produtosMaisVendidos = ranking.map((map) {
      return ProdutoRanking(
        nomeProduto: map['produto_nome'] as String,
        nomeVariacao: map['variacao_nome'] as String,
        quantidadeVendida: map['quantidade_vendida'] as int,
        valorTotal: (map['valor_total'] as num).toDouble(),
        lucro: (map['lucro'] as num).toDouble(),
      );
    }).toList();
  }

  /// Carrega vendas por forma de pagamento
  Future<void> _carregarVendasPorPagamento() async {
    final dados = await _databaseService.getVendasPorFormaPagamento();
    final totalGeral = dados.fold<double>(
      0,
      (sum, map) => sum + (map['valor_total'] as num).toDouble(),
    );

    _vendasPorPagamento = dados.map((map) {
      final valorTotal = (map['valor_total'] as num).toDouble();
      return VendasPorPagamento(
        formaPagamento: map['forma_pagamento'] as String,
        quantidadeVendas: map['quantidade_vendas'] as int,
        valorTotal: valorTotal,
        percentual: totalGeral > 0 ? (valorTotal / totalGeral) * 100 : 0,
      );
    }).toList();
  }

  /// Carrega alertas de estoque
  Future<void> _carregarAlertasEstoque() async {
    final variacoesBaixo = await _databaseService.getVariacoesWithEstoqueBaixo();
    final variacoesZerado = await _databaseService.getVariacoesWithEstoqueZerado();

    _estoquesBaixos = variacoesBaixo.length;
    _estoquesZerados = variacoesZerado.length;
  }

  /// Carrega vendas de um período específico
  Future<void> carregarVendasPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final diasDiferenca = fim.difference(inicio).inDays + 1;
      await _carregarVendasPorDia(diasAtras: diasDiferenca);

      // Recalcular estatísticas para o período
      _totalVendas = await _databaseService.calcularTotalVendas(
        inicio: inicio,
        fim: fim,
      );
      _totalLucro = await _databaseService.calcularTotalLucro(
        inicio: inicio,
        fim: fim,
      );
      _ticketMedio = await _databaseService.calcularTicketMedio(
        inicio: inicio,
        fim: fim,
      );

      if (_totalVendas > 0) {
        _margemLucro = (_totalLucro / _totalVendas) * 100;
      } else {
        _margemLucro = 0;
      }

      final vendas = await _databaseService.getVendasByPeriodo(inicio, fim);
      _quantidadeVendas = vendas.length;

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar período: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
