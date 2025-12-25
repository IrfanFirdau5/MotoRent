// FILE: lib/widgets/invoice_access_widget.dart
// ✅ NEW: Widget for accessing invoices (for both customer and owner)

import 'package:flutter/material.dart';
import 'dart:io';
import '../services/invoice_storage_service.dart';
import '../services/invoice_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceAccessWidget extends StatefulWidget {
  final String bookingId;
  final bool isOwner; // true if owner, false if customer

  const InvoiceAccessWidget({
    Key? key,
    required this.bookingId,
    this.isOwner = false,
  }) : super(key: key);

  @override
  State<InvoiceAccessWidget> createState() => _InvoiceAccessWidgetState();
}

class _InvoiceAccessWidgetState extends State<InvoiceAccessWidget> {
  final InvoiceStorageService _storageService = InvoiceStorageService();
  final InvoiceService _invoiceService = InvoiceService();
  
  bool _isLoading = false;
  bool _invoiceExists = false;
  String? _invoiceUrl;

  @override
  void initState() {
    super.initState();
    _checkInvoiceExists();
  }

  Future<void> _checkInvoiceExists() async {
    setState(() {
      _isLoading = true;
    });

    final exists = await _storageService.invoiceExists(widget.bookingId);
    
    if (exists) {
      final url = await _storageService.getInvoiceUrl(widget.bookingId);
      setState(() {
        _invoiceExists = exists;
        _invoiceUrl = url;
        _isLoading = false;
      });
    } else {
      setState(() {
        _invoiceExists = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _viewInvoice() async {
    if (_invoiceUrl == null) {
      _showMessage('Invoice not available', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Try to open in browser
      final uri = Uri.parse(_invoiceUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Could not open invoice', Colors.red);
      }
    } catch (e) {
      _showMessage('Error opening invoice: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndShare() async {
    if (_invoiceUrl == null) {
      _showMessage('Invoice not available', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Download invoice
      final invoiceFile = await _storageService.downloadInvoice(
        _invoiceUrl!,
        widget.bookingId,
      );

      if (invoiceFile != null) {
        // Share the invoice
        await _invoiceService.shareInvoice(invoiceFile);
      } else {
        _showMessage('Failed to download invoice', Colors.red);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndPrint() async {
    if (_invoiceUrl == null) {
      _showMessage('Invoice not available', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Download invoice
      final invoiceFile = await _storageService.downloadInvoice(
        _invoiceUrl!,
        widget.bookingId,
      );

      if (invoiceFile != null) {
        // Print the invoice
        await _invoiceService.printInvoice(invoiceFile);
      } else {
        _showMessage('Failed to download invoice', Colors.red);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_invoiceExists) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Invoice not yet generated',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Invoice exists - show action buttons
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[900], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOwner ? 'Invoice Available' : 'Your Invoice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${widget.bookingId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _viewInvoice,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[900],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _downloadAndShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[900],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _downloadAndPrint,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[900],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}