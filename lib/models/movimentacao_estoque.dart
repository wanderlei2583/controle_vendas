import 'variacao.dart';

/// Tipos de movimentação de estoque
enum TipoMovimentacao {
  entrada('Entrada'),
  saida('Saída'),
  ajuste('Ajuste'),
  vendaAutomatica('Venda Automática');

  final String displayName;

  const TipoMovimentacao(this.displayName);

  /// Converte string para enum
  static TipoMovimentacao fromString(String value) {
    return TipoMovimentacao.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoMovimentacao.entrada,
    );
  }
}

/// Modelo para Movimentação de Estoque (histórico)
class MovimentacaoEstoque {
  final int? id;
  final int variacaoId;
  final TipoMovimentacao tipo;
  final int quantidade;
  final int quantidadeAnterior;
  final int quantidadePosterior;
  final DateTime dataMovimentacao;
  final String? observacao;
  final int? vendaId; // Se a movimentação veio de uma venda

  // Relacionamento (carregado separadamente)
  Variacao? variacao;

  MovimentacaoEstoque({
    this.id,
    required this.variacaoId,
    required this.tipo,
    required this.quantidade,
    required this.quantidadeAnterior,
    required this.quantidadePosterior,
    DateTime? dataMovimentacao,
    this.observacao,
    this.vendaId,
    this.variacao,
  }) : dataMovimentacao = dataMovimentacao ?? DateTime.now();

  /// Retorna se é uma movimentação de entrada
  bool get isEntrada => tipo == TipoMovimentacao.entrada;

  /// Retorna se é uma movimentação de saída
  bool get isSaida =>
      tipo == TipoMovimentacao.saida || tipo == TipoMovimentacao.vendaAutomatica;

  /// Retorna se é uma movimentação de ajuste
  bool get isAjuste => tipo == TipoMovimentacao.ajuste;

  /// Retorna a diferença de quantidade
  int get diferenca => quantidadePosterior - quantidadeAnterior;

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'variacao_id': variacaoId,
      'tipo': tipo.name,
      'quantidade': quantidade,
      'quantidade_anterior': quantidadeAnterior,
      'quantidade_posterior': quantidadePosterior,
      'data_movimentacao': dataMovimentacao.toIso8601String(),
      'observacao': observacao,
      'venda_id': vendaId,
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory MovimentacaoEstoque.fromMap(Map<String, dynamic> map) {
    return MovimentacaoEstoque(
      id: map['id'] as int?,
      variacaoId: map['variacao_id'] as int,
      tipo: TipoMovimentacao.fromString(map['tipo'] as String),
      quantidade: map['quantidade'] as int,
      quantidadeAnterior: map['quantidade_anterior'] as int,
      quantidadePosterior: map['quantidade_posterior'] as int,
      dataMovimentacao: DateTime.parse(map['data_movimentacao'] as String),
      observacao: map['observacao'] as String?,
      vendaId: map['venda_id'] as int?,
    );
  }

  /// Cria cópia com alterações
  MovimentacaoEstoque copyWith({
    int? id,
    int? variacaoId,
    TipoMovimentacao? tipo,
    int? quantidade,
    int? quantidadeAnterior,
    int? quantidadePosterior,
    DateTime? dataMovimentacao,
    String? observacao,
    int? vendaId,
    Variacao? variacao,
  }) {
    return MovimentacaoEstoque(
      id: id ?? this.id,
      variacaoId: variacaoId ?? this.variacaoId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      quantidadeAnterior: quantidadeAnterior ?? this.quantidadeAnterior,
      quantidadePosterior: quantidadePosterior ?? this.quantidadePosterior,
      dataMovimentacao: dataMovimentacao ?? this.dataMovimentacao,
      observacao: observacao ?? this.observacao,
      vendaId: vendaId ?? this.vendaId,
      variacao: variacao ?? this.variacao,
    );
  }

  @override
  String toString() {
    return 'MovimentacaoEstoque{id: $id, tipo: ${tipo.displayName}, quantidade: $quantidade}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MovimentacaoEstoque && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
