import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/storage_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<File> _images = [];
  bool _uploading = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 10) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final home = context.read<HomeProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final token = auth.token!;
    final workplaceId =
        home.assignedWorkplace?.id ?? auth.currentUser?.assignedWorkplaceId;

    if (workplaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No workplace assigned. Contact admin.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStatus = '';
    });

    final storage = StorageService();
    final uploadedUrls = <String>[];
    final tempExpenseId = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < _images.length; i++) {
      setState(() =>
          _uploadStatus = 'Uploading bill ${i + 1} of ${_images.length}...');
      try {
        final url = await storage.uploadExpenseBill(
            _images[i], auth.currentUser!.id, tempExpenseId);
        uploadedUrls.add(url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed for image ${i + 1}: $e'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _uploading = false;
        });
        return;
      }
    }

    setState(() => _uploadStatus = 'Submitting expense...');

    final ok = await expenseProvider.submitExpense(
      token,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      workplaceId: workplaceId,
      billImageUrls: uploadedUrls,
    );

    setState(() {
      _uploading = false;
      _uploadStatus = '';
    });

    if (ok && mounted) {
      _descCtrl.clear();
      _amountCtrl.clear();
      _images.clear();
      _selectedDate = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Expense submitted!'),
            backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(expenseProvider.error ?? 'Failed to submit'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Date
              const Text('Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF1A56DB)),
                      const SizedBox(width: 10),
                      Text(DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'e.g. Fuel cost for site visit, Tools purchased...'),
                validator: (v) {
                  if (v == null || v.trim().length < 5)
                    return 'Description must be at least 5 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              const Text('Amount',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(prefixText: '₹ ', hintText: '0.00'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0)
                    return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bill Images
              const Text('Upload Bills (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add button
                    GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade400,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Color(0xFF1A56DB)),
                            SizedBox(height: 4),
                            Text('Add',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF1A56DB))),
                          ],
                        ),
                      ),
                    ),
                    // Thumbnails
                    ..._images.asMap().entries.map((entry) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                    image: FileImage(entry.value),
                                    fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(entry.key)),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              if (_uploading) ...[
                Text(_uploadStatus,
                    style: const TextStyle(
                        color: Color(0xFF1A56DB), fontSize: 13)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              Consumer<ExpenseProvider>(builder: (_, ep, __) {
                return ElevatedButton(
                  onPressed: (_uploading || ep.isSubmitting) ? null : _submit,
                  child: (_uploading || ep.isSubmitting)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Expense',
                          style: TextStyle(fontSize: 16)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
