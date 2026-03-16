import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  int? _lightboxIndex;

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(DateFormat('dd MMM yyyy').format(DateTime.parse(e.date)))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: e.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(e.statusLabel.toUpperCase(),
                    style: TextStyle(
                        color: e.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Amount', '₹${e.amount.toStringAsFixed(2)}',
                        bold: true, color: const Color(0xFF1A56DB)),
                    _row('Description', e.description),
                    _row(
                        'Date',
                        DateFormat('dd MMMM yyyy')
                            .format(DateTime.parse(e.date))),
                    if (e.submittedAt != null)
                      _row(
                          'Submitted',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.parse(e.submittedAt!))),
                  ],
                ),
              ),
            ),

            // Admin notes
            if (e.adminNotes != null && e.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: e.status == 'rejected'
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: e.statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Notes',
                        style: TextStyle(
                            fontSize: 12,
                            color: e.statusColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(e.adminNotes!, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],

            // Bill images
            if (e.billImageUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Bills (${e.billImageUrls.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: e.billImageUrls.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _lightboxIndex = i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(e.billImageUrls[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),

      // Lightbox
      extendBody: true,
      floatingActionButtonLocation: null,
      bottomSheet: _lightboxIndex == null
          ? null
          : GestureDetector(
              onTap: () => setState(() => _lightboxIndex = null),
              child: Container(
                color: Colors.black.withOpacity(0.92),
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                          child: InteractiveViewer(
                        child: Image.network(e.billImageUrls[_lightboxIndex!]),
                      )),
                      Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () =>
                                setState(() => _lightboxIndex = null),
                          )),
                      if (_lightboxIndex! > 0)
                        Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white, size: 36),
                              onPressed: () => setState(
                                  () => _lightboxIndex = _lightboxIndex! - 1),
                            )),
                      if (_lightboxIndex! < e.billImageUrls.length - 1)
                        Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white, size: 36),
                              onPressed: () => setState(
                                  () => _lightboxIndex = _lightboxIndex! + 1),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      color: color,
                      fontSize: 14))),
        ],
      ),
    );
  }
}
