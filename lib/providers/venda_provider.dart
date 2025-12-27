import 'package:flutter/foundation.dart';
import '../models/venda.dart';
import '../models/item_venda.dart';
import '../models/variacao.dart';
import '../models/produto.dart';
import '../models/forma_pagamento.dart';
import '../services/database/database_service.dart';
import 'estoque_provider.dart';

/// Item do carrinho de compras (antes de finalizar venda)
class CartItem {
  final Variacao variacao;
  final Produto produto;
  int quantidade;

  CartItem({
    required this.variacao,
    required this.produto,
    this.quantidade = 1,
  });

  double get subtotal => variacao.precoVenda * quantidade;
  double get custoUnitario => produto.custoUnitarioPorVariacao;
  double get custoTotal => custoUnitario * quantidade;
  double get lucro => subtotal - custoTotal;
  double get margemLucro => subtotal > 0 ? (lucro / subtotal) * 100 : 0;

  CartItem copyWith({
    Variacao? variacao,
    Produto? produto,
    int? quantidade,
  }) {
    return CartItem(
      variacao: variacao ?? this.variacao,
      produto: produto ?? this.produto,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}

/// Provider para gerenciar o estado das Vendas
class VendaProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final EstoqueProvider _estoqueProvider;

  List<Venda> _vendas = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Estado do carrinho
  final List<CartItem> _carrinho = [];
  FormaPagamento _formaPagamentoSelecionada = FormaPagamento.dinheiro;
  String? _observacoes;

  VendaProvider(this._databaseService, this._estoqueProvider) {
    carregarVendas();
  }

  // Getters
  List<Venda> get vendas => _vendas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getters do carrinho
  List<CartItem> get carrinho => _carrinho;
  bool get carrinhoVazio => _carrinho.isEmpty;
  int get quantidadeItensCarrinho => _carrinho.fold(0, (sum, item) => sum + item.quantidade);
  FormaPagamento get formaPagamentoSelecionada => _formaPagamentoSelecionada;
  String? get observacoes => _observacoes;

  // Cálculos do carrinho
  double get valorTotalCarrinho => _carrinho.fold(0.0, (sum, item) => sum + item.subtotal);
  double get custoTotalCarrinho => _carrinho.fold(0.0, (sum, item) => sum + item.custoTotal);
  double get lucroCarrinho => valorTotalCarrinho - custoTotalCarrinho;
  double get margemLucroCarrinho => valorTotalCarrinho > 0 ? (lucroCarrinho / valorTotalCarrinho) * 100 : 0;

  /// Carrega todas as vendas
  Future<void> carregarVendas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vendas = await _databaseService.getAllVendasWithItens();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar vendas: $e';
      _vendas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega vendas de um período específico
  Future<void> carregarVendasPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vendas = await _databaseService.getVendasByPeriodo(
        dataInicio,
        dataFim,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar vendas: $e';
      _vendas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca venda por ID com itens
  Future<Venda?> buscarVendaComItens(int id) async {
    try {
      return await _databaseService.getVendaByIdWithItens(id);
    } catch (e) {
      _errorMessage = 'Erro ao buscar venda: $e';
      notifyListeners();
      return null;
    }
  }

  // === GESTÃO DO CARRINHO ===

  /// Adiciona item ao carrinho
  Future<bool> adicionarAoCarrinho({
    required Variacao variacao,
    required Produto produto,
    int quantidade = 1,
  }) async {
    if (quantidade <= 0) {
      _errorMessage = 'Quantidade deve ser maior que zero';
      notifyListeners();
      return false;
    }

    // Verificar disponibilidade em estoque
    final disponivel = await _estoqueProvider.verificarDisponibilidade(
      variacaoId: variacao.id!,
      quantidade: quantidade,
    );

    if (!disponivel) {
      _errorMessage = 'Estoque insuficiente. Disponível: ${variacao.quantidadeEstoque}';
      notifyListeners();
      return false;
    }

    // Verificar se item já existe no carrinho
    final index = _carrinho.indexWhere((item) => item.variacao.id == variacao.id);

    if (index != -1) {
      // Atualizar quantidade
      final novaQuantidade = _carrinho[index].quantidade + quantidade;

      // Verificar disponibilidade da nova quantidade
      final disponivelNovo = await _estoqueProvider.verificarDisponibilidade(
        variacaoId: variacao.id!,
        quantidade: novaQuantidade,
      );

      if (!disponivelNovo) {
        _errorMessage = 'Estoque insuficiente para quantidade total. Disponível: ${variacao.quantidadeEstoque}';
        notifyListeners();
        return false;
      }

      _carrinho[index] = _carrinho[index].copyWith(quantidade: novaQuantidade);
    } else {
      // Adicionar novo item
      _carrinho.add(CartItem(
        variacao: variacao,
        produto: produto,
        quantidade: quantidade,
      ));
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Remove item do carrinho
  void removerDoCarrinho(int index) {
    if (index >= 0 && index < _carrinho.length) {
      _carrinho.removeAt(index);
      notifyListeners();
    }
  }

  /// Atualiza quantidade de um item no carrinho
  Future<bool> atualizarQuantidadeItem({
    required int index,
    required int novaQuantidade,
  }) async {
    if (index < 0 || index >= _carrinho.length) {
      _errorMessage = 'Item não encontrado no carrinho';
      notifyListeners();
      return false;
    }

    if (novaQuantidade <= 0) {
      removerDoCarrinho(index);
      return true;
    }

    final item = _carrinho[index];

    // Verificar disponibilidade
    final disponivel = await _estoqueProvider.verificarDisponibilidade(
      variacaoId: item.variacao.id!,
      quantidade: novaQuantidade,
    );

    if (!disponivel) {
      _errorMessage = 'Estoque insuficiente. Disponível: ${item.variacao.quantidadeEstoque}';
      notifyListeners();
      return false;
    }

    _carrinho[index] = item.copyWith(quantidade: novaQuantidade);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Limpa o carrinho
  void limparCarrinho() {
    _carrinho.clear();
    _formaPagamentoSelecionada = FormaPagamento.dinheiro;
    _observacoes = null;
    notifyListeners();
  }

  /// Define forma de pagamento
  void setFormaPagamento(FormaPagamento forma) {
    _formaPagamentoSelecionada = forma;
    notifyListeners();
  }

  /// Define observações
  void setObservacoes(String? obs) {
    _observacoes = obs;
    notifyListeners();
  }

  /// Finaliza a venda (grava no banco e baixa estoque)
  Future<bool> finalizarVenda() async {
    if (carrinhoVazio) {
      _errorMessage = 'Carrinho vazio';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Criar venda
      final venda = Venda(
        dataVenda: DateTime.now(),
        valorTotal: valorTotalCarrinho,
        custoTotal: custoTotalCarrinho,
        lucro: lucroCarrinho,
        formaPagamento: _formaPagamentoSelecionada,
        observacoes: _observacoes?.trim().isEmpty == true ? null : _observacoes?.trim(),
      );

      // Criar itens da venda (vendaId será definido no finalizarVenda)
      final itens = _carrinho.map((cartItem) {
        return ItemVenda(
          vendaId: 0, // Será atualizado pela transação
          variacaoId: cartItem.variacao.id!,
          quantidade: cartItem.quantidade,
          precoUnitario: cartItem.variacao.precoVenda,
          subtotal: cartItem.subtotal,
          custoUnitario: cartItem.custoUnitario,
        );
      }).toList();

      // Finalizar venda com transação (inclui baixa de estoque)
      await _databaseService.finalizarVenda(
        venda: venda,
        itens: itens,
      );

      // Recarregar vendas
      await carregarVendas();

      // Limpar carrinho
      limparCarrinho();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao finalizar venda: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Exclui uma venda
  /// ATENÇÃO: Não restaura estoque automaticamente
  Future<bool> excluirVenda(int id) async {
    try {
      await _databaseService.deleteVenda(id);
      _vendas.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir venda: $e';
      notifyListeners();
      return false;
    }
  }

  /// Retorna total de vendas do dia
  double get vendasDoDia {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return _vendas
        .where((v) =>
            v.dataVenda.isAfter(inicioDia) &&
            v.dataVenda.isBefore(fimDia))
        .fold(0.0, (sum, v) => sum + v.valorTotal);
  }

  /// Retorna lucro do dia
  double get lucroDoDia {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return _vendas
        .where((v) =>
            v.dataVenda.isAfter(inicioDia) &&
            v.dataVenda.isBefore(fimDia))
        .fold(0.0, (sum, v) => sum + v.lucro);
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
