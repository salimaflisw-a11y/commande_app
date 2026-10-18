import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../services/pdf_invoice_service.dart';

class PdfPreviewPage extends StatelessWidget {
  final OrderModel order;

  const PdfPreviewPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Reçu & Facture PDF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF263238),
              ),
            ),
            Text(
              order.id,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: primaryColor),
            tooltip: 'Partager le PDF',
            onPressed: () => PdfInvoiceService.printOrShare(order),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfInvoiceService.generateOrderPdf(order),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
        pdfFileName: 'Facture_${order.id}.pdf',
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.send_rounded),
            onPressed: (context, build, pageFormat) async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reçu PDF envoyé par e-mail au responsable ! 📧'),
                  backgroundColor: Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
