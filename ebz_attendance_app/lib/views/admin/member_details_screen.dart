import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_account.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../services/firestore_service.dart';

class MemberDetailsScreen extends StatefulWidget {
  final UserAccount user;

  const MemberDetailsScreen({super.key, required this.user});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar / Profile Info
          Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    widget.user.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Text(widget.user.name, style: Theme.of(context).textTheme.headlineSmall),
                Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 40),
                _buildInfoRow(Icons.badge, 'ID', widget.user.employeeId),
                _buildInfoRow(Icons.phone, 'Phone', widget.user.phoneNumber),
                _buildInfoRow(Icons.work, 'Role', 'Member'), // Assuming member
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                     // Edit Profile logic could go here
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          
          // Main Content / Attendance Log
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Log - ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<AttendanceRecord>>(
                      stream: _firestoreService.getAllAttendance(_selectedDate), // This gets SINGLE DAY. Wait, we want range.
                      // Adjusting logic: Let's show the LIST of days for the selected MONTH.
                      // But firestoreService.getAllAttendance(date) gets ALL users for ONE day.
                      // We want ONE user for MANY days.
                      // We need a new stream in FirestoreService: getUserAttendance(userId, startOfMonth, endOfMonth)
                      builder: (context, snapshot) {
                         // Temporary: using FutureBuilder with getAttendanceRange for now as stream logic needs update
                         DateTime start = DateTime(_selectedDate.year, _selectedDate.month, 1);
                         DateTime end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
                         return FutureBuilder<List<AttendanceRecord>>(
                           future: _firestoreService.getAttendanceRange(start, end), // This gets ALL users. 
                           // We need to filter client side or update service. 
                           // For now, let's filter client side.
                           builder: (context, snap) {
                             if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                             
                             final userRecords = snap.data!.where((r) => r.userId == widget.user.uid).toList();
                             userRecords.sort((a, b) => b.date.compareTo(a.date)); // Newest first

                             if (userRecords.isEmpty) {
                               return Center(
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                                     const SizedBox(height: 16),
                                     Text('No records found for this month', style: TextStyle(color: Colors.grey[500])),
                                   ],
                                 ),
                               );
                             }

                             return ListView.separated(
                               itemCount: userRecords.length,
                               separatorBuilder: (_, __) => const SizedBox(height: 12),
                               itemBuilder: (context, index) {
                                 final record = userRecords[index];
                                 return Card(
                                   child: ListTile(
                                     leading: Container(
                                       padding: const EdgeInsets.all(8),
                                       decoration: BoxDecoration(
                                         color: record.status == AttendanceStatus.present 
                                            ? Colors.green.withOpacity(0.1) 
                                            : Colors.orange.withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                       child: Icon(
                                         record.status == AttendanceStatus.present ? Icons.check : Icons.timer,
                                         color: record.status == AttendanceStatus.present ? Colors.green : Colors.orange,
                                       ),
                                     ),
                                     title: Text(DateFormat('EEEE, MMM d').format(record.date)),
                                     subtitle: Text(
                                       'In: ${record.checkIn != null ? DateFormat('hh:mm a').format(record.checkIn!) : "--:--"}  '
                                       '${record.checkOut != null ? "|  Out: ${DateFormat('hh:mm a').format(record.checkOut!)}" : ""}'
                                     ),
                                     trailing: IconButton(
                                       icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                       tooltip: 'Clear Status',
                                       onPressed: () => _confirmClearStatus(context, record),
                                     ),
                                   ),
                                 );
                               },
                             );
                           },
                         );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearStatus(BuildContext context, AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Status?'),
        content: const Text(
          'This will delete the attendance record for this day. '
          ' The member will be able to check in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final provider = Provider.of<AttendanceProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await provider.clearMemberStatus(record.userId, record.date);
                setState(() {}); // Refresh list
                if (mounted) {
                   messenger.showSnackBar(
                     const SnackBar(content: Text('Status cleared successfully.')),
                   );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
