import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_account.dart';
import '../../models/attendance_record.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isMobile ? _buildDrawer() : null,
      appBar: isMobile ? AppBar(
        title: const Text('Admin Portal'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ClipRRect(
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
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          _buildNavItem(0, 'Dashboard', Icons.grid_view_rounded),
          _buildNavItem(1, 'Directory', Icons.person_search_rounded),
          _buildNavItem(2, 'Compliance', Icons.rule_rounded),
          _buildNavItem(3, 'Analytics', Icons.bar_chart_rounded),
          const Spacer(),
          _buildLogoutBtn(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          ...List.generate(4, (index) => _buildNavItem(index, 
            ['Dashboard', 'Directory', 'Compliance', 'Analytics'][index],
            [Icons.grid_view_rounded, Icons.person_search_rounded, Icons.rule_rounded, Icons.bar_chart_rounded][index],
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
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Column(
        children: [
          Icon(Icons.radar_rounded, color: Colors.white, size: 40),
          SizedBox(height: 16),
          Text(
            'EBZ CORE',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {bool isDrawer = false}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
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
      padding: const EdgeInsets.all(32.0),
      child: TextButton.icon(
        onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
        icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
        label: const Text('SIGN OUT', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
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
      padding: const EdgeInsets.all(60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operational Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Systems are active and monitoring real-time activity.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              _buildDateBadge(),
            ],
          ),
          const SizedBox(height: 60),
          
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 32,
                  childAspectRatio: 1.5,
                ),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection('users').where('role', isEqualTo: 1).snapshots(),
                    builder: (context, snapshot) => StatCard(
                      title: 'Personnel',
                      value: snapshot.hasData ? snapshot.data!.docs.length.toString() : '...',
                      icon: Icons.people_outline_rounded,
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
                        title: 'Active Today',
                        value: clockedIn.toString(),
                        icon: Icons.check_circle_outline_rounded,
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
                      title: 'Exceptions',
                      value: snapshot.hasData ? snapshot.data!.docs.length.toString() : '...',
                      icon: Icons.error_outline_rounded,
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
                      icon: Icons.coffee_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 60),
          _buildRecentActivitySection(context, db),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        DateFormat('MMMM dd, yyyy').format(DateTime.now()),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, FirebaseFirestore db) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Live Personnel Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const Spacer(),
              const Icon(Icons.circle, color: Colors.green, size: 8),
              const SizedBox(width: 8),
              const Text('OPERATIONAL STATUS: ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black26)),
            ],
          ),
          const SizedBox(height: 60),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').where('role', isEqualTo: 1).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) return const Text('No records.');

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
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withOpacity(0.03)),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final record = records.where((r) => r.userId == member.uid).firstOrNull;
                      bool isCheckIn = record != null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(member.name[0], style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCheckIn 
                                      ? 'OPERATIONAL SINCE ${DateFormat('HH:mm').format(record.checkIn!)}' 
                                      : 'OFFLINE / INACTIVE',
                                    style: TextStyle(color: isCheckIn ? Colors.black45 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            if (isCheckIn) ...[
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.black.withOpacity(0.03),
                                   borderRadius: BorderRadius.circular(100),
                                 ),
                                 child: Text(
                                   record.status.name.toUpperCase(),
                                   style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                                 ),
                               ),
                               const SizedBox(width: 40),
                            ],
                            TextButton(
                              onPressed: isCheckIn ? () => _confirmReset(context, member, record) : null,
                              style: TextButton.styleFrom(
                                foregroundColor: isCheckIn ? Colors.redAccent.withOpacity(0.8) : Colors.black12,
                                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              child: const Text('PURGE STATUS'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('PURGE OPERATIONAL STATUS?'),
        content: Text('This action will reset the session for ${member.name.toUpperCase()}. Current records for this cycle will be invalidated.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
              try {
                await attendanceProvider.clearMemberStatus(member.uid, record.date);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SESSION PURGED'), backgroundColor: Colors.black));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('CONFIRM PURGE'),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 28),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
