/// Modelo para Variação de Produto (sub-módulos)
///
/// Exemplo: Produto "Chop" pode ter variações:
/// - "Chop de Vinho" (R$ 5.00)
/// - "Chop de Morango" (R$ 6.00)
class Variacao {
  final int? id;
  final int produtoId;
  final String nome;
  final double precoVenda;
  final int quantidadeEstoque;
  final int? estoqueMinimo; // Alerta quando estoque atingir este valor
  final bool ativo;
  final DateTime dataCriacao;

  Variacao({
    this.id,
    required this.produtoId,
    required this.nome,
    required this.precoVenda,
    this.quantidadeEstoque = 0,
    this.estoqueMinimo,
    this.ativo = true,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  /// Verifica se o estoque está baixo
  bool get estoqueBaixo {
    if (estoqueMinimo == null) return false;
    return quantidadeEstoque > 0 && quantidadeEstoque <= estoqueMinimo!;
  }

  /// Verifica se o estoque está zerado
  bool get estoqueZerado => quantidadeEstoque <= 0;

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'nome': nome,
      'preco_venda': precoVenda,
      'quantidade_estoque': quantidadeEstoque,
      'estoque_minimo': estoqueMinimo,
      'ativo': ativo ? 1 : 0,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory Variacao.fromMap(Map<String, dynamic> map) {
    return Variacao(
      id: map['id'] as int?,
      produtoId: map['produto_id'] as int,
      nome: map['nome'] as String,
      precoVenda: (map['preco_venda'] as num).toDouble(),
      quantidadeEstoque: map['quantidade_estoque'] as int,
      estoqueMinimo: map['estoque_minimo'] as int?,
      ativo: map['ativo'] == 1,
      dataCriacao: DateTime.parse(map['data_criacao'] as String),
    );
  }

  /// Cria cópia com alterações
  Variacao copyWith({
    int? id,
    int? produtoId,
    String? nome,
    double? precoVenda,
    int? quantidadeEstoque,
    int? estoqueMinimo,
    bool? ativo,
    DateTime? dataCriacao,
  }) {
    return Variacao(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      precoVenda: precoVenda ?? this.precoVenda,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  String toString() {
    return 'Variacao{id: $id, nome: $nome, preco: R\$ $precoVenda, estoque: $quantidadeEstoque}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Variacao && other.id == id && other.produtoId == produtoId;
  }

  @override
  int get hashCode => id.hashCode ^ produtoId.hashCode;
}
