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

    return Padding(
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
                    'Reports & Analytics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Analyze attendance data and export monthly records', 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final path = await reportProvider.exportMonthlyReport(_selectedDate);
                  if (path != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report saved to: $path'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  }
                },
                icon: reportProvider.isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded),
                label: const Text('Export Monthly (.xlsx)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildFilterBar(),
          
          const SizedBox(height: 24),
          
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: Colors.blueGrey),
          const SizedBox(width: 12),
          const Text('Viewing records for: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_month_rounded, size: 16),
            label: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
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
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
        border: Border.all(color: Colors.blueGrey.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: StreamBuilder<List<AttendanceRecord>>(
          stream: _firestoreService.getAllAttendance(_selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            if (records.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                bool isLate = record.status == AttendanceStatus.late;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isLate ? Colors.orange : Colors.teal).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLate ? Icons.timer_rounded : Icons.check_circle_rounded,
                      color: isLate ? Colors.orange : Colors.teal,
                    ),
                  ),
                  title: Text(
                    'User ID: ${record.userId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'In: ${record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--'} • '
                    'Out: ${record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--'}',
                    style: TextStyle(color: Colors.blueGrey[400]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isLate ? Colors.orange : Colors.teal).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLate ? Colors.orange[800] : Colors.teal[800],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 60, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          const Text('No records found', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          const Text('There are no attendance logs for this day.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
