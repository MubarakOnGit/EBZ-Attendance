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
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        Provider.of<AttendanceProvider>(context, listen: false).loadTodayRecord(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final user = authProvider.currentUser;
    final todayRecord = attendanceProvider.todayRecord;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserHeader(user?.name ?? 'User'),
            const SizedBox(height: 24),
            _buildStatusCard(todayRecord),
            const SizedBox(height: 32),
            if (todayRecord == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Check In', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: attendanceProvider.isLoading 
                  ? null 
                  : () async {
                      final error = await attendanceProvider.checkIn(user!);
                      if (error != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
              )
            else if (todayRecord.checkOut == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (todayRecord.lunchOut == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Lunch Out', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: attendanceProvider.isLoading 
                        ? null 
                        : () async {
                            final error = await attendanceProvider.lunchOut();
                            if (error != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            }
                          },
                    )
                  else if (todayRecord.lunchIn == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Lunch In', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: attendanceProvider.isLoading 
                        ? null 
                        : () async {
                            final error = await attendanceProvider.lunchIn();
                            if (error != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            }
                          },
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (attendanceProvider.isLoading || (todayRecord.lunchOut != null && todayRecord.lunchIn == null))
                      ? null 
                      : () async {
                          final error = await attendanceProvider.checkOut();
                          if (error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                  ),
                ],
              )
            else
              const Center(
                child: Text(
                  'Checked out for today!',
                  style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 48),
            const Text('Month Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String name) {
    return Column(
      children: [
        CircleAvatar(radius: 40, child: Text(name[0], style: const TextStyle(fontSize: 32))),
        const SizedBox(height: 8),
        Text('Hello, $name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusCard(AttendanceRecord? record) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              record == null ? 'Not Checked In' : 'Current Status: ${record.status.name.toUpperCase()}',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: record == null ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo('In', record?.checkIn),
                const VerticalDivider(thickness: 1, width: 20),
                _buildTimeInfo('Out', record?.checkOut),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, DateTime? time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : '--:--',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1,
      children: [
        _buildSummaryItem('Present', '20', Colors.green),
        _buildSummaryItem('Late', '2', Colors.orange),
        _buildSummaryItem('Absent', '1', Colors.red),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
