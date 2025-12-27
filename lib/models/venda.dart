import 'forma_pagamento.dart';
import 'item_venda.dart';

/// Modelo para Venda
class Venda {
  final int? id;
  final DateTime dataVenda;
  final double valorTotal;
  final double custoTotal;
  final double lucro;
  final FormaPagamento formaPagamento;
  final String? observacoes;

  // Relacionamento (carregado separadamente)
  List<ItemVenda> itens;

  Venda({
    this.id,
    DateTime? dataVenda,
    required this.valorTotal,
    required this.custoTotal,
    required this.lucro,
    required this.formaPagamento,
    this.observacoes,
    this.itens = const [],
  }) : dataVenda = dataVenda ?? DateTime.now();

  /// Calcula margem de lucro em percentual
  double get margemLucro {
    if (valorTotal == 0) return 0;
    return (lucro / valorTotal) * 100;
  }

  /// Retorna quantidade total de itens vendidos
  int get quantidadeItens {
    return itens.fold(0, (sum, item) => sum + item.quantidade);
  }

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_venda': dataVenda.toIso8601String(),
      'valor_total': valorTotal,
      'custo_total': custoTotal,
      'lucro': lucro,
      'forma_pagamento': formaPagamento.name,
      'observacoes': observacoes,
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory Venda.fromMap(Map<String, dynamic> map) {
    return Venda(
      id: map['id'] as int?,
      dataVenda: DateTime.parse(map['data_venda'] as String),
      valorTotal: (map['valor_total'] as num).toDouble(),
      custoTotal: (map['custo_total'] as num).toDouble(),
      lucro: (map['lucro'] as num).toDouble(),
      formaPagamento: FormaPagamento.fromString(map['forma_pagamento'] as String),
      observacoes: map['observacoes'] as String?,
    );
  }

  /// Cria cópia com alterações
  Venda copyWith({
    int? id,
    DateTime? dataVenda,
    double? valorTotal,
    double? custoTotal,
    double? lucro,
    FormaPagamento? formaPagamento,
    String? observacoes,
    List<ItemVenda>? itens,
  }) {
    return Venda(
      id: id ?? this.id,
      dataVenda: dataVenda ?? this.dataVenda,
      valorTotal: valorTotal ?? this.valorTotal,
      custoTotal: custoTotal ?? this.custoTotal,
      lucro: lucro ?? this.lucro,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      observacoes: observacoes ?? this.observacoes,
      itens: itens ?? this.itens,
    );
  }

  @override
  String toString() {
    return 'Venda{id: $id, valorTotal: R\$ $valorTotal, lucro: R\$ $lucro, itens: ${itens.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Venda && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
