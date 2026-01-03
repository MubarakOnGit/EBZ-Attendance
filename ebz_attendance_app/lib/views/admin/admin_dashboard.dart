import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_account.dart';
import '../../models/attendance_record.dart';
import '../../widgets/enhanced_stat_card.dart';
import '../../widgets/live_activity_indicator.dart';
import '../../widgets/charts/attendance_trend_chart.dart';
import '../../widgets/charts/status_distribution_chart.dart';
import '../../widgets/charts/peak_hours_chart.dart';
import '../../widgets/live_clock.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/top_performers.dart';
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
          AnimatedEntrance(
            delay: const Duration(milliseconds: 200),
            child: Row(
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
                    Row(
                      children: [
                        const LiveActivityIndicator(isActive: true, color: Colors.green, size: 8),
                        const SizedBox(width: 12),
                        Text(
                          'Systems online • Real-time monitoring active',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const LiveClock(),
              ],
            ),
          ),
          const SizedBox(height: 60),
          
          // Enhanced Stat Cards with trends
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').where('role', isEqualTo: 1).snapshots(),
            builder: (context, usersSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: db.collection('attendance')
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  final totalPersonnel = usersSnapshot.hasData ? usersSnapshot.data!.docs.length : 0;
                  final todayRecords = attendanceSnapshot.hasData
                      ? attendanceSnapshot.data!.docs
                          .map((doc) => AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>))
                          .toList()
                      : <AttendanceRecord>[];

                  final activeToday = todayRecords.length;
                  final lateToday = todayRecords.where((r) => r.status == AttendanceStatus.late).length;
                  final onTimeToday = todayRecords.where((r) => r.status == AttendanceStatus.present).length;
                  final lunchActive = todayRecords.where((r) => r.lunchOut != null && r.lunchIn == null).length;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 1400 ? 5 : (constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.4,
                        ),
                        children: [
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 300),
                            child: EnhancedStatCard(
                              title: 'Personnel',
                              value: totalPersonnel.toString(),
                              icon: Icons.people_outline_rounded,
                              trend: '100%',
                              isPositive: true,
                              percentageChange: 'TOTAL',
                            ),
                          ),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: EnhancedStatCard(
                              title: 'Active Today',
                              value: activeToday.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              trend: totalPersonnel > 0 ? '${((activeToday / totalPersonnel) * 100).toStringAsFixed(0)}%' : '0%',
                              isPositive: true,
                              percentageChange: 'PRESENT',
                            ),
                          ),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 500),
                            child: EnhancedStatCard(
                              title: 'On Time',
                              value: onTimeToday.toString(),
                              icon: Icons.schedule_rounded,
                              trend: activeToday > 0 ? '${((onTimeToday / activeToday) * 100).toStringAsFixed(0)}%' : '0%',
                              isPositive: true,
                              percentageChange: 'PUNCTUAL',
                            ),
                          ),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 600),
                            child: EnhancedStatCard(
                              title: 'On Break',
                              value: lunchActive.toString(),
                              icon: Icons.coffee_rounded,
                              trend: activeToday > 0 ? '${((lunchActive / activeToday) * 100).toStringAsFixed(0)}%' : '0%',
                              isPositive: true,
                              percentageChange: 'LUNCH',
                            ),
                          ),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 700),
                            child: EnhancedStatCard(
                              title: 'Exceptions',
                              value: lateToday.toString(),
                              icon: Icons.error_outline_rounded,
                              trend: activeToday > 0 ? '${((lateToday / activeToday) * 100).toStringAsFixed(0)}%' : '0%',
                              isPositive: false,
                              percentageChange: 'LATE',
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 60),

          // Charts Section
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('attendance').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRecords = snapshot.data!.docs
                  .map((doc) => AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              // Calculate 7-day trend
              final sevenDaysAgo = today.subtract(const Duration(days: 6));
              final dailyData = <DateTime, int>{};
              for (int i = 0; i < 7; i++) {
                final date = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day + i);
                final count = allRecords.where((r) {
                  final recordDate = r.date;
                  return recordDate.year == date.year &&
                      recordDate.month == date.month &&
                      recordDate.day == date.day;
                }).length;
                dailyData[date] = count;
              }

              // Calculate hourly data for today
              final hourlyData = <int, int>{};
              final todayRecords = allRecords.where((r) {
                final recordDate = r.date;
                return recordDate.year == today.year &&
                    recordDate.month == today.month &&
                    recordDate.day == today.day;
              }).toList();

              for (final record in todayRecords) {
                if (record.checkIn != null) {
                  final hour = record.checkIn!.hour;
                  hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
                }
              }

              // Status distribution
              final onTimeCount = todayRecords.where((r) => r.status == AttendanceStatus.present).length;
              final lateCount = todayRecords.where((r) => r.status == AttendanceStatus.late).length;
              final absentCount = 0; // We only have records for those who checked in

              return Column(
                children: [
                  // Attendance Trend Chart
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 800),
                    child: AttendanceTrendChart(dailyData: dailyData),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Status Distribution and Peak Hours
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1000) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedEntrance(
                                delay: const Duration(milliseconds: 900),
                                child: StatusDistributionChart(
                                  onTimeCount: onTimeCount,
                                  lateCount: lateCount,
                                  absentCount: absentCount,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: AnimatedEntrance(
                                delay: const Duration(milliseconds: 1000),
                                child: PeakHoursChart(hourlyData: hourlyData),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 900),
                              child: StatusDistributionChart(
                                onTimeCount: onTimeCount,
                                lateCount: lateCount,
                                absentCount: absentCount,
                              ),
                            ),
                            const SizedBox(height: 40),
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 1000),
                              child: PeakHoursChart(hourlyData: hourlyData),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 60),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2, 
                      child: AnimatedEntrance(
                        delay: const Duration(milliseconds: 1100),
                        child: _buildRecentActivitySection(context, db),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 1, 
                      child: AnimatedEntrance(
                        delay: const Duration(milliseconds: 1200),
                        child: const TopPerformersWidget(),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 1100),
                      child: _buildRecentActivitySection(context, db),
                    ),
                    const SizedBox(height: 40),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 1200),
                      child: const TopPerformersWidget(),
                    ),
                  ],
                );
              }
            },
          ),
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
                            Stack(
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
                                if (isCheckIn)
                                  const Positioned(
                                    right: 0,
                                    top: 0,
                                    child: LiveActivityIndicator(isActive: true, color: Colors.green, size: 10),
                                  ),
                              ],
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
