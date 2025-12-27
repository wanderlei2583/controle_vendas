/// Modelo para Categoria de Produtos
class Categoria {
  final int? id;
  final String nome;
  final String? descricao;
  final String? icone; // Nome do ícone Material (ex: 'fastfood', 'local_drink')
  final String cor; // Hex color string (ex: '#FF5722')
  final DateTime dataCriacao;

  Categoria({
    this.id,
    required this.nome,
    this.descricao,
    this.icone,
    required this.cor,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  /// Converte objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'icone': icone,
      'cor': cor,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  /// Cria objeto a partir de Map (ao ler do banco)
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      icone: map['icone'] as String?,
      cor: map['cor'] as String,
      dataCriacao: DateTime.parse(map['data_criacao'] as String),
    );
  }

  /// Cria cópia com alterações
  Categoria copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? icone,
    String? cor,
    DateTime? dataCriacao,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  @override
  String toString() {
    return 'Categoria{id: $id, nome: $nome}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Categoria &&
        other.id == id &&
        other.nome == nome &&
        other.descricao == descricao &&
        other.icone == icone &&
        other.cor == cor;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        descricao.hashCode ^
        icone.hashCode ^
        cor.hashCode;
  }
}
