import 'variacao.dart';

/// Modelo para Item de Venda (produto vendido em uma venda)
class ItemVenda {
  final int? id;
  final int vendaId;
  final int variacaoId;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  final double custoUnitario; // Para cálculo de lucro

  // Relacionamento (carregado separadamente)
  Variacao? variacao;

  ItemVenda({
    this.id,
    required this.vendaId,
    required this.variacaoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    required this.custoUnitario,
    this.variacao,
  });

  /// Calcula o lucro deste item
  double get lucro {
    final custoTotal = custoUnitario * quantidade;
    return subtotal - custoTotal;
  }

  /// Calcula a margem de lucro em percentual
  double get margemLucro {
    if (subtotal == 0) return 0;
    return (lucro / subtotal) * 100;
  }

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venda_id': vendaId,
      'variacao_id': variacaoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
      'custo_unitario': custoUnitario,
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory ItemVenda.fromMap(Map<String, dynamic> map) {
    return ItemVenda(
      id: map['id'] as int?,
      vendaId: map['venda_id'] as int,
      variacaoId: map['variacao_id'] as int,
      quantidade: map['quantidade'] as int,
      precoUnitario: (map['preco_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      custoUnitario: (map['custo_unitario'] as num).toDouble(),
    );
  }

  /// Cria cópia com alterações
  ItemVenda copyWith({
    int? id,
    int? vendaId,
    int? variacaoId,
    int? quantidade,
    double? precoUnitario,
    double? subtotal,
    double? custoUnitario,
    Variacao? variacao,
  }) {
    return ItemVenda(
      id: id ?? this.id,
      vendaId: vendaId ?? this.vendaId,
      variacaoId: variacaoId ?? this.variacaoId,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      subtotal: subtotal ?? this.subtotal,
      custoUnitario: custoUnitario ?? this.custoUnitario,
      variacao: variacao ?? this.variacao,
    );
  }

  @override
  String toString() {
    return 'ItemVenda{id: $id, quantidade: $quantidade, subtotal: R\$ $subtotal}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ItemVenda &&
        other.id == id &&
        other.vendaId == vendaId &&
        other.variacaoId == variacaoId;
  }

  @override
  int get hashCode => id.hashCode ^ vendaId.hashCode ^ variacaoId.hashCode;
}
