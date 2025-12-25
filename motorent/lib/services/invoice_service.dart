import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/vehicle.dart';
import '../models/user.dart';

class InvoiceService {
  /// Generate invoice PDF for a booking
  Future<File> generateInvoice({
    required Booking booking,
    required Vehicle vehicle,
    required User customer,
    required User owner,
    String? paymentIntentId,
  }) async {
    final pdf = pw.Document();

    // Add invoice page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Logo placeholder and Title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo area
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'LOGO\nHERE',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey500,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Invoice title and company info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'MOTORENT',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '+60 10-973 688 (Phone)',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'motorent@gmail.com',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Invoice details (Invoice No, Date)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice No:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          booking.bookingId.toString(),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Bill To and Owner Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Bill To (Customer)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            customer.name,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            customer.email,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            customer.phone,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            customer.address,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Owner Info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Owner:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            owner.name,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            owner.email,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            owner.phone,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue700,
                      ),
                      children: [
                        _buildTableCell('Item', isHeader: true),
                        _buildTableCell('Description', isHeader: true),
                        _buildTableCell('QTY/DAY(S)/HOURS', isHeader: true),
                        _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                      ],
                    ),
                    
                    // Vehicle Rental Row
                    pw.TableRow(
                      children: [
                        _buildTableCell('1)'),
                        _buildTableCell(vehicle.fullName),
                        _buildTableCell('${booking.duration} day${booking.duration > 1 ? 's' : ''}'),
                        _buildTableCell(
                          'RM ${booking.vehiclePrice.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                    
                    // Driver Service Row (if applicable)
                    if (booking.needDriver && booking.driverPrice != null)
                      pw.TableRow(
                        children: [
                          _buildTableCell('2)'),
                          _buildTableCell('Driver Service'),
                          _buildTableCell('${booking.duration} day${booking.duration > 1 ? 's' : ''}'),
                          _buildTableCell(
                            'RM ${booking.driverPrice!.toStringAsFixed(2)}',
                            align: pw.TextAlign.right,
                          ),
                        ],
                      ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Booking Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Booking Details',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Pickup Date', DateFormat('EEEE, dd MMM yyyy').format(booking.startDate)),
                      _buildDetailRow('Return Date', DateFormat('EEEE, dd MMM yyyy').format(booking.endDate)),
                      _buildDetailRow('Duration', '${booking.duration} day${booking.duration > 1 ? 's' : ''}'),
                      _buildDetailRow('Vehicle', vehicle.fullName),
                      _buildDetailRow('License Plate', vehicle.licensePlate),
                      if (booking.needDriver)
                        _buildDetailRow('Driver Service', 'Included'),
                      if (paymentIntentId != null)
                        _buildDetailRow('Payment ID', paymentIntentId),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue700, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'RM ${booking.totalPrice.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'MOTORENT',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'THANK YOU FOR YOUR BUSINESS.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${booking.bookingId}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Helper: Build table cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  /// Helper: Build detail row
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Open/share invoice PDF
  Future<void> shareInvoice(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  /// Print invoice
  Future<void> printInvoice(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }

  /// Save invoice to device storage
  Future<String?> saveInvoiceToStorage(File pdfFile) async {
    try {
      // This would require additional permissions and storage access
      // For now, just return the temp file path
      return pdfFile.path;
    } catch (e) {
      print('Error saving invoice: $e');
      return null;
    }
  }
}