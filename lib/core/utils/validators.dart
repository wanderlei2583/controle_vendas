/// Validadores para formulários
class Validators {
  /// Valida campo obrigatório
  ///
  /// Retorna mensagem de erro se o campo estiver vazio, null caso contrário
  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Valida valor monetário
  ///
  /// Verifica se o valor é um número válido e maior que zero
  static String? currency(String? value, {bool allowZero = false}) {
    if (value == null || value.isEmpty) {
      return 'Valor é obrigatório';
    }

    // Remove formatação de moeda
    String cleanValue = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    final parsed = double.tryParse(cleanValue);

    if (parsed == null) {
      return 'Valor inválido';
    }

    if (!allowZero && parsed <= 0) {
      return 'Valor deve ser maior que zero';
    }

    if (allowZero && parsed < 0) {
      return 'Valor não pode ser negativo';
    }

    return null;
  }

  /// Valida quantidade (número inteiro)
  ///
  /// Verifica se é um número inteiro válido e dentro do range especificado
  static String? integer(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Quantidade é obrigatória';
    }

    final parsed = int.tryParse(value);

    if (parsed == null) {
      return 'Quantidade deve ser um número inteiro';
    }

    if (min != null && parsed < min) {
      return 'Quantidade deve ser no mínimo $min';
    }

    if (max != null && parsed > max) {
      return 'Quantidade deve ser no máximo $max';
    }

    return null;
  }

  /// Valida tamanho mínimo de texto
  static String? minLength(String? value, int min, {String fieldName = 'Campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }

    if (value.length < min) {
      return '$fieldName deve ter no mínimo $min caracteres';
    }

    return null;
  }

  /// Valida tamanho máximo de texto
  static String? maxLength(String? value, int max, {String fieldName = 'Campo'}) {
    if (value != null && value.length > max) {
      return '$fieldName deve ter no máximo $max caracteres';
    }

    return null;
  }

  /// Valida email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }

    return null;
  }

  /// Combina múltiplos validadores
  ///
  /// Retorna a primeira mensagem de erro encontrada ou null se todos passarem
  static String? combine(List<String? Function()> validators) {
    for (var validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Valida se o valor é positivo
  static String? positive(num? value, {String fieldName = 'Valor'}) {
    if (value == null) {
      return '$fieldName é obrigatório';
    }

    if (value <= 0) {
      return '$fieldName deve ser positivo';
    }

    return null;
  }

  /// Valida se o valor não é negativo (pode ser zero)
  static String? nonNegative(num? value, {String fieldName = 'Valor'}) {
    if (value == null) {
      return '$fieldName é obrigatório';
    }

    if (value < 0) {
      return '$fieldName não pode ser negativo';
    }

    return null;
  }
}
