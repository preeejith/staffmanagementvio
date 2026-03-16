import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/expense_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final home = context.watch<HomeProvider>();
    final ep = context.watch<ExpenseProvider>();
    final user = auth.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    final approved = ep.expenses.where((e) => e.status == 'approved').length;
    final pending = ep.expenses.where((e) => e.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user.role.toUpperCase(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info
                  const Text('Personal Info',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email),
                        if (user.phone != null) ...[
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: user.phone!),
                        ],
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Employee ID',
                            value: user.id.substring(0, 8).toUpperCase()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workplace
                  if (home.assignedWorkplace != null) ...[
                    const Text('Workplace',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Card(
                      child: _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'Assigned To',
                        value: home.assignedWorkplace!.name,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Expense summary
                  const Text('This Month',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              'Total',
                              '₹${ep.totalAmount.toStringAsFixed(0)}',
                              Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              _StatCard('Pending', '$pending', Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              _StatCard('Approved', '$approved', Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Coming soon
                  const Text('Coming Soon',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  for (final item in ['Leave Management', 'Attendance'])
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lock_clock_outlined,
                            color: Colors.grey),
                        title: Text(item,
                            style: const TextStyle(color: Colors.grey)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('Coming Soon',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Logout
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600)),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () async {
                                Navigator.pop(context);
                                await context.read<AuthProvider>().logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/login', (_) => false);
                                }
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A56DB)),
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
