import 'package:intl/intl.dart';

/// Formatador de moeda em Real brasileiro (R$)
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formata um valor double para String em formato de moeda brasileira
  ///
  /// Exemplo: 1234.56 → "R\$ 1.234,56"
  static String format(double value) => _formatter.format(value);

  /// Converte uma String de moeda para double
  ///
  /// Aceita formatos: "R\$ 1.234,56", "1.234,56", "1234,56", "1234.56"
  /// Retorna null se a conversão falhar
  static double? parse(String value) {
    try {
      // Remove símbolo de moeda e espaços
      String cleanValue = value
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .trim();

      // Se estiver em formato brasileiro (1.234,56), converte para formato padrão
      if (cleanValue.contains(',')) {
        cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
      }

      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  /// Formata um valor para exibição sem o símbolo R$
  ///
  /// Exemplo: 1234.56 → "1.234,56"
  static String formatWithoutSymbol(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }
}
