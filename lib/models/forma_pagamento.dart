/// Formas de pagamento aceitas
enum FormaPagamento {
  dinheiro('Dinheiro'),
  pix('PIX'),
  credito('Cartão de Crédito'),
  debito('Cartão de Débito'),
  transferencia('Transferência'),
  outro('Outro');

  final String displayName;

  const FormaPagamento(this.displayName);

  /// Converte string para enum
  static FormaPagamento fromString(String value) {
    return FormaPagamento.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormaPagamento.dinheiro,
    );
  }

  /// Retorna todas as formas de pagamento como lista de strings
  static List<String> get allDisplayNames {
    return FormaPagamento.values.map((e) => e.displayName).toList();
  }
}
