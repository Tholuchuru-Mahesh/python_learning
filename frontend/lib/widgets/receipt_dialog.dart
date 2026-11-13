import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';

class ReceiptDialog extends StatelessWidget {
  final Bill bill;

  const ReceiptDialog({super.key, required this.bill});

  static void show(BuildContext context, Bill bill) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReceiptDialog(bill: bill),
    );
  }

  Future<void> _printReceipt() async {
    final doc = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                bill.shopName ?? 'Retail POS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              if (bill.receiptHeader != null && bill.receiptHeader!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    bill.receiptHeader!,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.Divider(thickness: 0.5),

              // Reprint watermark banner if applicable (PRD §5.3)
              if (bill.isReprint || bill.reprintCount > 0)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Text(
                    '*** DUPLICATE / REPRINT ***',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill #: ${bill.billNumber}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(df.format(bill.createdAt), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (bill.staffName != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Cashier: ${bill.staffName}', style: const pw.TextStyle(fontSize: 9)),
                ),
              pw.Divider(thickness: 0.5),

              // Table header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(flex: 2, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items
              ...bill.items.map((i) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(i.productName, style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${i.quantity.toStringAsFixed(i.quantity % 1 == 0 ? 0 : 2)} ${i.unit}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${bill.shopCurrency}${i.unitPrice.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${bill.shopCurrency}${i.lineTotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.5),

              // Totals
              _buildPdfSummaryRow('Subtotal', '${bill.shopCurrency}${bill.subtotal.toStringAsFixed(2)}'),
              if (bill.discountAmount > 0)
                _buildPdfSummaryRow('Discount', '-${bill.shopCurrency}${bill.discountAmount.toStringAsFixed(2)}'),
              if (bill.taxAmount > 0)
                _buildPdfSummaryRow('Tax', '+${bill.shopCurrency}${bill.taxAmount.toStringAsFixed(2)}'),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(
                    '${bill.shopCurrency}${bill.finalTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),

              if (bill.receiptFooter != null && bill.receiptFooter!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    bill.receiptFooter!,
                    style: const pw.TextStyle(fontSize: 8.5),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'receipt-${bill.billNumber}.pdf',
    );
  }

  pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final isReprint = bill.isReprint || bill.reprintCount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Header
            Text(
              bill.shopName ?? 'Store Receipt',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (bill.receiptHeader != null && bill.receiptHeader!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  bill.receiptHeader!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Reprint Watermark Badge (PRD §5.3)
            if (isReprint)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  border: Border.all(color: Colors.amber.shade800),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '*** REPRINT OF RECEIPT ***',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const Divider(height: 20),

            // Bill metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bill #: ${bill.billNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(df.format(bill.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            if (bill.staffName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Cashier: ${bill.staffName}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),

            const Divider(height: 16),

            // Item list scrollable
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bill.items.length,
                separatorBuilder: (_, index) => const Divider(height: 8, thickness: 0.5),
                itemBuilder: (ctx, idx) {
                  final item = bill.items[idx];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit} x ${bill.shopCurrency}${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${bill.shopCurrency}${item.lineTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(height: 16),

            // Financial Summary
            _buildSummaryRow('Subtotal', '${bill.shopCurrency}${bill.subtotal.toStringAsFixed(2)}'),
            if (bill.discountAmount > 0)
              _buildSummaryRow('Discount', '-${bill.shopCurrency}${bill.discountAmount.toStringAsFixed(2)}', color: Colors.green),
            if (bill.taxAmount > 0)
              _buildSummaryRow('Tax', '+${bill.shopCurrency}${bill.taxAmount.toStringAsFixed(2)}'),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${bill.shopCurrency}${bill.finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                ),
              ],
            ),

            if (bill.receiptFooter != null && bill.receiptFooter!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  bill.receiptFooter!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _printReceipt,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Receipt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

