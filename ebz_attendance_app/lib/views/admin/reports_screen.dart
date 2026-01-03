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
                    'Operational Analytics',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Comprehensive attendance data and system performance reports.', 
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final path = await reportProvider.exportMonthlyReport(_selectedDate);
                  if (path != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report successfully exported: $path'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.black,
                      ),
                    );
                  }
                },
                icon: reportProvider.isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.description_rounded, size: 20),
                label: const Text('Export Analytics (.xlsx)'),
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          _buildFilterBar(),
          
          const SizedBox(height: 32),
          
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: Colors.black26, size: 20),
          const SizedBox(width: 16),
          const Text('TEMPORAL SCOPE:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.black26)),
          const SizedBox(width: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(_selectedDate).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
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
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withOpacity(0.03)),
              itemBuilder: (context, index) {
                final record = records[index];
                bool isLate = record.status == AttendanceStatus.late;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                          child: Icon(
                            isLate ? Icons.timer_rounded : Icons.check_circle_outline_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${record.userId}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ACTIVE: ${record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--'} TO ${record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--'}',
                              style: TextStyle(color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(isLate ? 0.05 : 0.03),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          record.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: isLate ? Colors.redAccent : Colors.black,
                          ),
                        ),
                      ),
                    ],
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
          Icon(Icons.history_rounded, size: 60, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No operational logs found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: Colors.black.withOpacity(0.2))),
        ],
      ),
    );
  }
}
