import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        Provider.of<AttendanceProvider>(context, listen: false).loadTodayRecord(userId);
        Provider.of<AttendanceProvider>(context, listen: false).loadMonthRecords(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final user = authProvider.currentUser;
    final todayRecord = attendanceProvider.todayRecord;
    final monthRecords = attendanceProvider.monthRecords;

    // Calculate Summary Stats
    int present = monthRecords.where((r) => r.status == AttendanceStatus.present).length;
    int lateCount = monthRecords.where((r) => r.status == AttendanceStatus.late).length;
    
    // Simple Absent Calculation: Days of month passed - total records
    final now = DateTime.now();
    int daysPassed = now.day; // Up to today
    int totalRecords = monthRecords.length;
    int absentCount = (daysPassed - totalRecords).clamp(0, 31);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(user?.name ?? 'Member'),
            const SizedBox(height: 32),
            _buildStatusCard(todayRecord),
            const SizedBox(height: 32),
            _buildActionButtons(attendanceProvider, todayRecord, user),
            const SizedBox(height: 48),
            const Text('Month Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: TextStyle(color: Colors.blueGrey[300])),
            const SizedBox(height: 16),
            _buildSummaryGrid(present, lateCount, absentCount),
            const SizedBox(height: 48),
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _buildRecentLogs(monthRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28, 
          backgroundColor: Colors.indigoAccent.withOpacity(0.1),
          child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(AttendanceRecord? record) {
    bool isCheckIn = record != null;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCheckIn ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)] : [Colors.blueGrey[800]!, Colors.blueGrey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCheckIn ? Colors.indigoAccent : Colors.blueGrey).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCheckIn ? 'YOU ARE ACTIVE' : 'NOT CLOCKED IN',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2),
              ),
              if (isCheckIn) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(record.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernTimeInfo('Entry', record?.checkIn),
              Container(height: 40, width: 1, color: Colors.white12),
              _buildModernTimeInfo('Exit', record?.checkOut),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTimeInfo(String label, DateTime? time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : '--:--',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AttendanceProvider provider, AttendanceRecord? record, dynamic user) {
     if (record == null) {
      return _actionButton(
        label: 'Swipe to Check In', 
        icon: Icons.login_rounded, 
        color: Colors.indigoAccent,
        onPressed: () async {
          final err = await provider.checkIn(user);
          if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        },
      );
    }
    
    if (record.checkOut != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Work day completed!', style: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.w700))),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _halfActionButton(
                label: record.lunchOut == null ? 'Lunch Break' : (record.lunchIn == null ? 'Return' : 'Lunch Done'),
                icon: Icons.restaurant_rounded,
                color: record.lunchOut == null ? Colors.orange : (record.lunchIn == null ? Colors.teal : Colors.blueGrey),
                onPressed: record.lunchIn != null ? null : () async {
                  final err = record.lunchOut == null ? await provider.lunchOut() : await provider.lunchIn();
                  if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _halfActionButton(
                label: 'Checkout',
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onPressed: (record.lunchOut != null && record.lunchIn == null) ? null : () async {
                  final err = await provider.checkOut();
                  if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _halfActionButton({required String label, required IconData icon, required Color color, required VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.2), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: color.withOpacity(0.05),
        foregroundColor: color,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(int present, int late, int absent) {
    return Row(
      children: [
        Expanded(child: _summaryStat('Present', present.toString(), Colors.teal)),
        const SizedBox(width: 12),
        Expanded(child: _summaryStat('Late', late.toString(), Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _summaryStat('Absent', absent.toString(), Colors.redAccent)),
      ],
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text('No activity this month yet.', style: TextStyle(color: Colors.blueGrey[300]))),
      );
    }

    final recentRecords = records..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentRecords.take(5).length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = recentRecords[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50]?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(DateFormat('dd').format(record.date), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(DateFormat('MMM').format(record.date).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.status.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: record.status == AttendanceStatus.present ? Colors.teal : Colors.orange)),
                    Text(
                      record.checkOut != null ? 'Full Day worked' : 'Active Shift',
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(record.checkIn != null ? DateFormat('hh:mm').format(record.checkIn!) : '--:--', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(record.checkOut != null ? DateFormat('hh:mm').format(record.checkOut!) : '--:--', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
