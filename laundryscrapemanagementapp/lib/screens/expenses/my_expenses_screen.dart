import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import 'expense_detail_screen.dart';

class MyExpensesScreen extends StatefulWidget {
  const MyExpensesScreen({super.key});

  @override
  State<MyExpensesScreen> createState() => _MyExpensesScreenState();
}

class _MyExpensesScreenState extends State<MyExpensesScreen> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    context
        .read<ExpenseProvider>()
        .loadMyExpenses(auth.token!, status: _filterStatus);
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final status in [
                    null,
                    'pending',
                    'approved',
                    'rejected'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status?.toUpperCase() ?? 'ALL',
                            style: TextStyle(
                                fontSize: 12,
                                color: _filterStatus == status
                                    ? Colors.white
                                    : null)),
                        selected: _filterStatus == status,
                        selectedColor: const Color(0xFF1A56DB),
                        onSelected: (_) {
                          setState(() => _filterStatus = status);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ep.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ep.expenses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No expenses yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Add your first expense!',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ep.expenses.length,
                    itemBuilder: (_, i) =>
                        _ExpenseItem(expense: ep.expenses[i]),
                  ),
                ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ExpenseDetailScreen(expense: expense))),
        leading: CircleAvatar(
          backgroundColor: expense.statusColor.withOpacity(0.15),
          child: Icon(Icons.receipt_outlined,
              color: expense.statusColor, size: 20),
        ),
        title: Text(expense.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date)),
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${expense.amount.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: expense.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(expense.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: expense.statusColor,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
