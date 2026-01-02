import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'member_list_screen.dart';
import 'rules_config_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: [
          _buildDashboardItem(
            context,
            'Members',
            Icons.people,
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberListScreen())),
          ),
          _buildDashboardItem(
            context,
            'Salary Rules',
            Icons.rule,
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesConfigScreen())),
          ),
          _buildDashboardItem(
            context,
            'Reports',
            Icons.assessment,
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
