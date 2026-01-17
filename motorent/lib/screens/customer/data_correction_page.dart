// FILE: motorent/lib/screens/customer/data_correction_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DataCorrectionPage extends StatefulWidget {
  final String userId;
  
  const DataCorrectionPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<DataCorrectionPage> createState() => _DataCorrectionPageState();
}

class _DataCorrectionPageState extends State<DataCorrectionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedField;
  final _currentValueController = TextEditingController();
  final _newValueController = TextEditingController();
  final _reasonController = TextEditingController();
  final List<String> _attachments = [];
  bool _isSubmitting = false;

  final Map<String, List<String>> _dataFields = {
    'Personal Information': [
      'Full Name',
      'NRIC Number',
      'Date of Birth',
      'Gender',
    ],
    'Contact Information': [
      'Email Address',
      'Phone Number',
      'Residential Address',
      'Mailing Address',
    ],
    'Driver Information': [
      'License Number',
      'License Class',
      'License Expiry Date',
    ],
    'Financial Information': [
      'Payment Method',
      'Billing Address',
    ],
  };

  // Mock current data
  final Map<String, String> _currentData = {
    'Full Name': 'Ahmad Zahari bin Abdullah',
    'NRIC Number': '901234-56-7890',
    'Email Address': 'ahmad.zahari@email.com',
    'Phone Number': '+60 12-345 6789',
    'Residential Address': 'No. 123, Jalan Tun Razak, 50400 Kuala Lumpur',
    'License Number': 'D1234567',
  };

  @override
  void dispose() {
    _currentValueController.dispose();
    _newValueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onFieldSelected(String field) {
    setState(() {
      _selectedField = field;
      _currentValueController.text = _currentData[field] ?? '';
      _newValueController.clear();
      _reasonController.clear();
      _attachments.clear();
    });
  }

  Future<void> _addAttachment() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _attachments.add(image.name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attached: ${image.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Request Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your correction request has been submitted successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reference Number:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'COR-2026-00123',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'What happens next:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildNextStep('We will review your request within 7 days'),
                  _buildNextStep('You may be contacted for verification'),
                  _buildNextStep('Updates will be made within 14 days'),
                  _buildNextStep('You will receive an email confirmation'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    // Reset form
    setState(() {
      _selectedField = null;
      _currentValueController.clear();
      _newValueController.clear();
      _reasonController.clear();
      _attachments.clear();
    });
  }

  Widget _buildNextStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Corrections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✏️ Correct Your Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Under PDPA 2010 Section 30, you have the right to correct inaccurate or incomplete personal data.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We will review your request within 21 days and update your records within 14 days after verification.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Field to Correct',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category dropdowns
                    ..._dataFields.entries.map((category) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: category.value.map((field) {
                              final isSelected = _selectedField == field;
                              return ChoiceChip(
                                label: Text(field),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) _onFieldSelected(field);
                                },
                                selectedColor: const Color(0xFF1E88E5),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),

                    if (_selectedField != null) ...[
                      const Divider(height: 32),
                      
                      const Text(
                        'Current Value',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentValueController,
                        enabled: false,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.visibility_off),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Correct Value',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newValueController,
                        decoration: InputDecoration(
                          hintText: 'Enter the correct value',
                          prefixIcon: const Icon(Icons.edit),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the correct value';
                          }
                          if (value == _currentValueController.text) {
                            return 'New value must be different from current value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Reason for Correction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Explain why this needs to be corrected (e.g., typo, outdated information, name change)',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.description),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide a reason for the correction';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Supporting Documents
                      const Text(
                        'Supporting Documents (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attach proof if applicable (NRIC, license, official documents)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_attachments.isNotEmpty) ...[
                              ..._attachments.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.attach_file, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _attachments.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _addAttachment,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Add Document'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Request',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}