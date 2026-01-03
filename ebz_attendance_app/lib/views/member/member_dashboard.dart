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
    
    final now = DateTime.now();
    int daysPassed = now.day;
    int totalRecords = monthRecords.length;
    int absentCount = (daysPassed - totalRecords).clamp(0, 31);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black),
              onPressed: () => authProvider.logout(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(user?.name ?? 'Member'),
            const SizedBox(height: 32),
            _buildStatusCard(todayRecord),
            const SizedBox(height: 32),
            _buildActionButtons(attendanceProvider, todayRecord, user),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                Text(DateFormat('MMMM').format(now), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryGrid(present, lateCount, absentCount),
            const SizedBox(height: 48),
            Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _buildRecentLogs(monthRecords),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text('Hi, $name', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }

  Widget _buildStatusCard(AttendanceRecord? record) {
    bool isCheckIn = record != null;
    bool isWorking = isCheckIn && record.checkOut == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isWorking ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isWorking ? 0.2 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWorking ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isWorking ? 'WORKING NOW' : (isCheckIn ? 'SHIFT ENDED' : 'NOT STARTED'),
                  style: TextStyle(
                    color: isWorking ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (isCheckIn)
                Text(
                  record.status.name.toUpperCase(),
                  style: TextStyle(
                    color: isWorking ? Colors.white70 : Colors.black45,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildTimeDisplay('Check In', record?.checkIn, isWorking)),
              Container(width: 1, height: 40, color: isWorking ? Colors.white12 : Colors.black12),
              Expanded(child: _buildTimeDisplay('Check Out', record?.checkOut, isWorking)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(String label, DateTime? time, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black45,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : '--:--',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AttendanceProvider provider, AttendanceRecord? record, dynamic user) {
    if (record == null) {
      return SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton.icon(
          onPressed: () async {
            final err = await provider.checkIn(user);
            if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          },
          icon: const Icon(Icons.login_rounded, size: 20),
          label: const Text('Check In'),
        ),
      );
    }
    
    if (record.checkOut != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'See you tomorrow!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 70,
            child: OutlinedButton.icon(
              onPressed: record.lunchIn != null ? null : () async {
                final err = record.lunchOut == null ? await provider.lunchOut() : await provider.lunchIn();
                if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              },
              icon: Icon(
                record.lunchOut == null ? Icons.restaurant_rounded : Icons.keyboard_return_rounded,
                size: 20,
              ),
              label: Text(record.lunchOut == null ? 'Lunch' : 'Return'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 70,
            child: ElevatedButton.icon(
              onPressed: (record.lunchOut != null && record.lunchIn == null) ? null : () async {
                final err = await provider.checkOut();
                if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Checkout'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(int present, int late, int absent) {
    return Row(
      children: [
        Expanded(child: _summaryCard('Present', present.toString(), Colors.black)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Late', late.toString(), Colors.black38)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Absent', absent.toString(), Colors.redAccent)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: const Center(child: Text('No activity yet')),
      );
    }

    final recentRecords = records..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: recentRecords.take(5).map((record) => _buildLogItem(record)).toList(),
    );
  }

  Widget _buildLogItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  DateFormat('MMM').format(record.date).toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.status.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: record.status == AttendanceStatus.present ? Colors.black : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.checkOut != null ? 'Full work day' : 'Active shift',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.checkIn != null ? DateFormat('hh:mm').format(record.checkIn!) : '--:--',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                record.checkOut != null ? DateFormat('hh:mm').format(record.checkOut!) : '--:--',
                style: const TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
