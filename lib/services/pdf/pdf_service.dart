import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/venda.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

/// Serviço para geração de PDFs
class PDFService {
  /// Gera PDF de recibo de venda
  static Future<void> gerarReciboPDF(Venda venda) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECIBO DE VENDA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Controle de Vendas',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Informações da venda
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Número da Venda:', '#${venda.id}'),
                    _buildInfoRow(
                      'Data:',
                      DateFormatter.formatDateTime(venda.dataVenda),
                    ),
                    _buildInfoRow(
                      'Forma de Pagamento:',
                      venda.formaPagamento.displayName,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Título dos itens
              pw.Text(
                'Itens da Venda',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              // Tabela de itens
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Cabeçalho
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableHeader('Produto'),
                      _buildTableHeader('Qtd'),
                      _buildTableHeader('Preço Unit.'),
                      _buildTableHeader('Subtotal'),
                    ],
                  ),
                  // Itens
                  ...venda.itens.map((item) => pw.TableRow(
                        children: [
                          _buildTableCell(item.nomeProduto),
                          _buildTableCell(item.quantidade.toString()),
                          _buildTableCell(
                            CurrencyFormatter.format(item.precoUnitario),
                          ),
                          _buildTableCell(
                            CurrencyFormatter.format(item.subtotal),
                          ),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 30),

              // Totais
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildTotalRow(
                      'Valor Total:',
                      CurrencyFormatter.format(venda.valorTotal),
                      bold: true,
                      fontSize: 18,
                    ),
                    if (venda.observacoes != null &&
                        venda.observacoes!.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Observações:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(venda.observacoes!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.Spacer(),

              // Rodapé
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Gerado em ${DateFormatter.formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await _salvarECompartilharPDF(
      pdf,
      'recibo_venda_${venda.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Gera PDF de relatório de vendas por período
  static Future<void> gerarRelatorioPDF({
    required DateTime inicio,
    required DateTime fim,
    required List<Venda> vendas,
    required double totalVendas,
    required double totalLucro,
    required double ticketMedio,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RELATÓRIO DE VENDAS',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Período: ${DateFormatter.formatDate(inicio)} a ${DateFormatter.formatDate(fim)}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Resumo
            pw.Text(
              'Resumo Financeiro',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildResumoRow('Total de Vendas:', vendas.length.toString()),
                  pw.SizedBox(height: 8),
                  _buildResumoRow(
                    'Valor Total:',
                    CurrencyFormatter.format(totalVendas),
                  ),
                  pw.SizedBox(height: 8),
                  _buildResumoRow(
                    'Lucro Total:',
                    CurrencyFormatter.format(totalLucro),
                  ),
                  pw.SizedBox(height: 8),
                  _buildResumoRow(
                    'Ticket Médio:',
                    CurrencyFormatter.format(ticketMedio),
                  ),
                  pw.SizedBox(height: 8),
                  _buildResumoRow(
                    'Margem de Lucro:',
                    '${totalVendas > 0 ? ((totalLucro / totalVendas) * 100).toStringAsFixed(1) : '0.0'}%',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Lista de vendas
            pw.Text(
              'Detalhamento das Vendas',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),

            // Tabela de vendas
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Cabeçalho
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableHeader('ID'),
                    _buildTableHeader('Data'),
                    _buildTableHeader('Valor'),
                    _buildTableHeader('Lucro'),
                    _buildTableHeader('Pagamento'),
                  ],
                ),
                // Vendas
                ...vendas.map((venda) => pw.TableRow(
                      children: [
                        _buildTableCell('#${venda.id}'),
                        _buildTableCell(
                          DateFormatter.formatDateTime(venda.dataVenda),
                        ),
                        _buildTableCell(
                          CurrencyFormatter.format(venda.valorTotal),
                        ),
                        _buildTableCell(
                          CurrencyFormatter.format(venda.lucro),
                        ),
                        _buildTableCell(venda.formaPagamento.displayName),
                      ],
                    )),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Gerado em ${DateFormatter.formatDateTime(DateTime.now())} - Página ${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await _salvarECompartilharPDF(
      pdf,
      'relatorio_vendas_${DateFormatter.formatDate(inicio).replaceAll('/', '-')}_${DateFormatter.formatDate(fim).replaceAll('/', '-')}.pdf',
    );
  }

  /// Widget helper: linha de informação
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  /// Widget helper: cabeçalho de tabela
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Widget helper: célula de tabela
  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  /// Widget helper: linha de total
  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 14,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper: linha de resumo
  static pw.Widget _buildResumoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value),
      ],
    );
  }

  /// Salva o PDF e compartilha
  static Future<void> _salvarECompartilharPDF(
    pw.Document pdf,
    String fileName,
  ) async {
    try {
      // Salva o PDF em um arquivo temporário
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Compartilha o PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PDF - Controle de Vendas',
      );
    } catch (e) {
      throw Exception('Erro ao salvar/compartilhar PDF: $e');
    }
  }

  /// Visualiza o PDF na tela (para pré-visualização)
  static Future<void> visualizarPDF(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Erro ao visualizar PDF: $e');
    }
  }

  /// Imprime o PDF
  static Future<void> imprimirPDF(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Erro ao imprimir PDF: $e');
    }
  }
}
