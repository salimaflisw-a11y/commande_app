import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class PdfInvoiceService {
  /// Generates a complete and beautifully styled PDF document for an order
  static Future<Uint8List> generateOrderPdf(OrderModel order) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final formattedDate = dateFormat.format(order.createdAt);
    final primaryColor = PdfColor.fromHex('#E65100');
    final darkColor = PdfColor.fromHex('#263238');
    final lightGrey = PdfColor.fromHex('#F5F5F5');
    final borderGrey = PdfColor.fromHex('#E0E0E0');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // ── HEADER ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GOURMET RESTAURANT',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Service de Commande Digitalisée & Restauration',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    '12 Avenue de la Gastronomie, 75008 Paris',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Tél: +33 1 42 68 00 00  •  SIRET: 894 123 456 00018',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BON DE COMMANDE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ADDITION DÉTAILLÉE',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 18),
          pw.Divider(color: primaryColor, thickness: 1.5),
          pw.SizedBox(height: 12),

          // ── ORDER & CUSTOMER INFO BOXES ───────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Order metadata box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderGrey),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RÉFÉRENCE COMMANDE',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _buildPdfMetaRow('N° Commande:', order.id),
                      _buildPdfMetaRow('Date / Heure:', formattedDate),
                      _buildPdfMetaRow('Type:', order.orderType),
                      if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                        _buildPdfMetaRow('Emplacement:', order.tableNumber!),
                      if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                        _buildPdfMetaRow('Adresse:', order.deliveryAddress!),
                      _buildPdfMetaRow('Statut:', 'Transmise en cuisine (En direct)'),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(width: 14),

              // Customer & Payment box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderGrey),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFOS CLIENT & RÈGLEMENT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _buildPdfMetaRow('Client:', order.customerName),
                      _buildPdfMetaRow('Téléphone:', order.customerPhone),
                      _buildPdfMetaRow('Règlement:', order.paymentMethod),
                      if (order.specialNotes.isNotEmpty)
                        _buildPdfMetaRow('Instructions:', order.specialNotes),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── TABLE OF ITEMS ───────────────────────────────────────────────
          pw.Text(
            'DÉTAIL DES ARTICLES & SUPPLÉMENTS',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: borderGrey, width: 0.5),
              bottom: pw.BorderSide(color: darkColor, width: 1),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6), // N°
              1: const pw.FlexColumnWidth(4.0), // Article & détails
              2: const pw.FlexColumnWidth(1.0), // Qté
              3: const pw.FlexColumnWidth(1.4), // P.U. TTC
              4: const pw.FlexColumnWidth(1.4), // Total TTC
            },
            children: [
              // Table Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableCell('N°', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('Désignation & Suppléments', isHeader: true),
                  _buildTableCell('Qté', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('P.U. TTC', isHeader: true, align: pw.TextAlign.right),
                  _buildTableCell('Total TTC', isHeader: true, align: pw.TextAlign.right),
                ],
              ),

              // Rows for each cart item
              ...order.items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final cartItem = entry.value;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isEven ? lightGrey : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell('$index', align: pw.TextAlign.center),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            cartItem.item.name,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: darkColor,
                            ),
                          ),
                          pw.Text(
                            'Catégorie: ${cartItem.item.category.label}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                          // Removed ingredients
                          if (cartItem.removedIngredients.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                '• Retiré: ${cartItem.removedIngredients.join(', ')}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.red800,
                                ),
                              ),
                            ),
                          // Added supplements
                          if (cartItem.supplements.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: cartItem.supplements.map((sup) {
                                  return pw.Text(
                                    '+ ${sup.name} x${sup.quantity} (+${sup.totalPrice.toStringAsFixed(2)} €)',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor.fromHex('#2E7D32'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          // Extra instructions note
                          if (cartItem.specialInstructions.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                'Note: "${cartItem.specialInstructions}"',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontStyle: pw.FontStyle.italic,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildTableCell('${cartItem.quantity}', align: pw.TextAlign.center),
                    _buildTableCell(
                      '${cartItem.unitPrice.toStringAsFixed(2)} €',
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      '${cartItem.totalPrice.toStringAsFixed(2)} €',
                      align: pw.TextAlign.right,
                      isBold: true,
                    ),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── TOTALS & ADDITION BREAKDOWN WITH TVA ──────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: QR code for order verification and check-in
              pw.Container(
                width: 170,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderGrey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.BarcodeWidget(
                      data: 'RESTAURANT-${order.id}-TOTAL-${order.totalTtc.toStringAsFixed(2)}EUR',
                      barcode: pw.Barcode.qrCode(),
                      width: 60,
                      height: 60,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Vérification Commande',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      order.id,
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              // Right: Addition box with TVA
              pw.Container(
                width: 250,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderGrey),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfTotalLine('Sous-total Hors Taxes (HT):', '${order.subtotalHt.toStringAsFixed(2)} €'),
                    pw.SizedBox(height: 5),
                    _buildPdfTotalLine('T.V.A. (10.00%):', '${order.vatAmount.toStringAsFixed(2)} €'),
                    pw.SizedBox(height: 5),
                    pw.Divider(color: primaryColor, thickness: 1),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL TTC À PAYER:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          '${order.totalTtc.toStringAsFixed(2)} €',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          // ── FOOTER & LEGAL MENTIONS ───────────────────────────────────────
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Merci pour votre confiance et excellent appétit ! 🍽️',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Ce document tient lieu de bon de commande officiel et de justificatif de paiement.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Gourmet Restaurant SAS • Capital 50.000 € • TVA Intracommunautaire: FR 89 123456789',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColor.fromHex('#263238'),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTotalLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Direct helper to print or share PDF
  static Future<void> printOrShare(OrderModel order) async {
    final pdfBytes = await generateOrderPdf(order);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Commande_${order.id}.pdf',
    );
  }
}
