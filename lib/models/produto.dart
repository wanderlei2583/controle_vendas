import 'categoria.dart';
import 'variacao.dart';

/// Modelo para Produto
class Produto {
  final int? id;
  final String nome;
  final String? descricao;
  final int categoriaId;
  final double custoTotal; // Custo total do produto (para cálculo de lucro)
  final DateTime dataCriacao;
  final bool ativo;

  // Relacionamentos (carregados separadamente)
  List<Variacao> variacoes;
  Categoria? categoria;

  Produto({
    this.id,
    required this.nome,
    this.descricao,
    required this.categoriaId,
    required this.custoTotal,
    DateTime? dataCriacao,
    this.ativo = true,
    this.variacoes = const [],
    this.categoria,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  /// Calcula o custo unitário por variação
  /// (divide o custo total pela quantidade de variações)
  double get custoUnitarioPorVariacao {
    if (variacoes.isEmpty) return custoTotal;
    return custoTotal / variacoes.length;
  }

  /// Retorna quantidade total em estoque (soma de todas as variações)
  int get quantidadeTotalEstoque {
    return variacoes.fold(0, (sum, v) => sum + v.quantidadeEstoque);
  }

  /// Verifica se tem alguma variação com estoque baixo
  bool get temEstoqueBaixo {
    return variacoes.any((v) => v.estoqueBaixo);
  }

  /// Verifica se tem alguma variação com estoque zerado
  bool get temEstoqueZerado {
    return variacoes.any((v) => v.estoqueZerado);
  }

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'categoria_id': categoriaId,
      'custo_total': custoTotal,
      'data_criacao': dataCriacao.toIso8601String(),
      'ativo': ativo ? 1 : 0,
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      categoriaId: map['categoria_id'] as int,
      custoTotal: (map['custo_total'] as num).toDouble(),
      dataCriacao: DateTime.parse(map['data_criacao'] as String),
      ativo: map['ativo'] == 1,
    );
  }

  /// Cria cópia com alterações
  Produto copyWith({
    int? id,
    String? nome,
    String? descricao,
    int? categoriaId,
    double? custoTotal,
    DateTime? dataCriacao,
    bool? ativo,
    List<Variacao>? variacoes,
    Categoria? categoria,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoriaId: categoriaId ?? this.categoriaId,
      custoTotal: custoTotal ?? this.custoTotal,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
      variacoes: variacoes ?? this.variacoes,
      categoria: categoria ?? this.categoria,
    );
  }

  @override
  String toString() {
    return 'Produto{id: $id, nome: $nome, variacoes: ${variacoes.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Produto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
