import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'member_list_screen.dart';
import 'rules_config_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminOverview(),
    const MemberListScreen(),
    const RulesConfigScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isMobile ? _buildDrawer() : null,
      appBar: isMobile ? AppBar(title: const Text('EBZ Admin')) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 32),
          _buildNavItem(0, 'Overview', Icons.dashboard_rounded),
          _buildNavItem(1, 'Members', Icons.people_rounded),
          _buildNavItem(2, 'Salary Rules', Icons.settings_suggest_rounded),
          _buildNavItem(3, 'Reports', Icons.assessment_rounded),
          const Spacer(),
          _buildLogoutBtn(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          ...List.generate(4, (index) => _buildNavItem(index, 
            ['Overview', 'Members', 'Salary Rules', 'Reports'][index],
            [Icons.dashboard_rounded, Icons.people_rounded, Icons.settings_suggest_rounded, Icons.assessment_rounded][index],
            isDrawer: true,
          )),
          const Spacer(),
          _buildLogoutBtn(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Text(
            'EBZ ADMIN',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {bool isDrawer = false}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey[600], size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBtn() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: InkWell(
        onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.blueGrey[900]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time analytics for your organization',
                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 16),
                  ),
                ],
              ),
              const Spacer(),
              _buildDateChip(),
            ],
          ),
          const SizedBox(height: 40),
          
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.6,
                ),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection('users').where('role', isEqualTo: 1).snapshots(),
                    builder: (context, snapshot) => StatCard(
                      title: 'Total Members',
                      value: snapshot.hasData ? snapshot.data!.docs.length.toString() : '...',
                      icon: Icons.group_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection('attendance')
                        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                        .snapshots(),
                    builder: (context, snapshot) {
                      int clockedIn = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return StatCard(
                        title: 'Clocked In',
                        value: clockedIn.toString(),
                        icon: Icons.login_rounded,
                        color: Colors.teal,
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection('attendance')
                        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                        .where('status', isEqualTo: 1) // Assuming 1 is Late
                        .snapshots(),
                    builder: (context, snapshot) => StatCard(
                      title: 'Late Arrivals',
                      value: snapshot.hasData ? snapshot.data!.docs.length.toString() : '...',
                      icon: Icons.timer_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection('attendance')
                        .where('isLunchOut', isEqualTo: true)
                        .where('isLunchIn', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) => StatCard(
                      title: 'On Break',
                      value: snapshot.hasData ? snapshot.data!.docs.length.toString() : '...',
                      icon: Icons.restaurant_rounded,
                      color: Colors.purple,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          _buildRecentActivitySection(context, db),
        ],
      ),
    );
  }

  Widget _buildDateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            DateTime.now().toString().split(' ')[0],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, FirebaseFirestore db) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.blueGrey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Today\'s Presence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.refresh_rounded, size: 18), 
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').where('role', isEqualTo: 1).snapshots(), // Members
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) return const Text('No members found.');

              final members = userSnapshot.data!.docs.map((doc) => UserAccount.fromMap(doc.data() as Map<String, dynamic>)).toList();

              final today = DateTime.now();
              final startOfDay = DateTime(today.year, today.month, today.day);
              final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

              return StreamBuilder<QuerySnapshot>(
                stream: db.collection('attendance')
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  final records = (attendanceSnapshot.data?.docs ?? [])
                      .map((doc) => AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>))
                      .toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final record = records.where((r) => r.userId == member.uid).firstOrNull;
                      bool isCheckIn = record != null;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: Text(member.name[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isCheckIn 
                            ? 'Checked In at ${DateFormat('hh:mm a').format(record.checkIn!)}' 
                            : 'Not Checked In',
                          style: TextStyle(color: isCheckIn ? Colors.teal : Colors.blueGrey[300], fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCheckIn) ...[
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: (record.status == AttendanceStatus.present ? Colors.teal : Colors.orange).withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(6),
                                 ),
                                 child: Text(
                                   record.status.name.toUpperCase(),
                                   style: TextStyle(
                                     fontSize: 10, 
                                     fontWeight: FontWeight.bold, 
                                     color: record.status == AttendanceStatus.present ? Colors.teal : Colors.orange[800],
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                            ],
                            OutlinedButton(
                              onPressed: isCheckIn ? () => _confirmReset(context, member, record) : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: isCheckIn ? const BorderSide(color: Colors.redAccent) : null,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Reset', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, UserAccount member, AttendanceRecord record) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Status?'),
        content: Text('Are you sure you want to clear the check-in status for ${member.name}? They will be able to check in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
              try {
                await attendanceProvider.clearMemberStatus(member.uid, record.date);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status reset successfully.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withOpacity(0.02)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Icon(Icons.more_horiz_rounded, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blueGrey[900]),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
