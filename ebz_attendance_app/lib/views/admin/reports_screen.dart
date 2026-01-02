import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/report_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/attendance_record.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: reportProvider.isExporting 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Icon(Icons.download),
            onPressed: () async {
              final path = await reportProvider.exportMonthlyReport(_selectedDate);
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to: $path')));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDatePicker(),
          const Divider(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Selected Date'),
      subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _firestoreService.getAllAttendance(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No attendance records for this day.'));
        }

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return ListTile(
              leading: Icon(
                record.status == AttendanceStatus.late ? Icons.warning : Icons.check_circle,
                color: record.status == AttendanceStatus.late ? Colors.orange : Colors.green,
              ),
              title: Text('User ID: ${record.userId}'), // Better to fetch name
              subtitle: Text(
                'In: ${record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--'} | '
                'Out: ${record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--'}'
              ),
              trailing: Text(record.status.name.toUpperCase()),
            );
          },
        );
      },
    );
  }
}
