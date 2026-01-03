import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_account.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/salary_calculator.dart';
import '../../widgets/animated_count.dart';
import '../../widgets/animated_entrance.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.user.name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
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
            width: 380,
            padding: const EdgeInsets.all(60),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      widget.user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(widget.user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text(widget.user.email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 60),
                _buildInfoRow(Icons.badge_outlined, 'PERSONNEL ID', widget.user.employeeId),
                _buildInfoRow(Icons.phone_outlined, 'CONTACT', widget.user.phoneNumber),
                _buildInfoRow(Icons.corporate_fare_rounded, 'DEPARTMENT', 'CORE OPERATIONS'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('MODIFY PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content / Attendance Log
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const Spacer(),
                      const Icon(Icons.circle, color: Colors.black, size: 8),
                      const SizedBox(width: 8),
                      const Text('OPERATIONAL LOGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 48),
                  _buildMonthlySummaryCard(context),
                  const SizedBox(height: 60),
                  StreamBuilder<List<AttendanceRecord>>(
                    stream: _firestoreService.getAllAttendance(_selectedDate), 
                    builder: (context, snapshot) {
                       DateTime start = DateTime(_selectedDate.year, _selectedDate.month, 1);
                       DateTime end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
                       return FutureBuilder<List<AttendanceRecord>>(
                         future: _firestoreService.getAttendanceRange(start, end), 
                         builder: (context, snap) {
                           if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                           
                           final userRecords = snap.data!.where((r) => r.userId == widget.user.uid).toList();
                           userRecords.sort((a, b) => b.date.compareTo(a.date));

                           if (userRecords.isEmpty) {
                             return Center(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Icon(Icons.event_busy_rounded, size: 80, color: Colors.black.withOpacity(0.05)),
                                   const SizedBox(height: 24),
                                   Text('NO LOGS FOR THIS CYCLE', style: TextStyle(color: Colors.black.withOpacity(0.2), fontWeight: FontWeight.w900, letterSpacing: 1)),
                                 ],
                               ),
                             );
                           }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: userRecords.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final record = userRecords[index];
                                
                                String lunchInfo = "0M";
                                bool lunchOverLimit = false;
                                if (record.lunchOut != null && record.lunchIn != null) {
                                  final diff = record.lunchIn!.difference(record.lunchOut!);
                                  lunchInfo = "${diff.inMinutes}M";
                                  if (diff.inMinutes > 60) lunchOverLimit = true;
                                }

                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                                  ),
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
                                            record.status == AttendanceStatus.present ? Icons.check_circle_outline_rounded : Icons.timer_rounded,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(DateFormat('EEEE, MMM dd').format(record.date).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _smallTag('IN: ${record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : "--"}'),
                                                const SizedBox(width: 8),
                                                _smallTag('OUT: ${record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : "--"}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('REST INTERVAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1)),
                                          const SizedBox(height: 4),
                                          Text(lunchInfo, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: lunchOverLimit ? Colors.redAccent : Colors.black)),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      IconButton(
                                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.black26, size: 22),
                                        onPressed: () => _confirmClearStatus(context, record),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.3)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black45)),
    );
  }

  void _confirmClearStatus(BuildContext context, AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('PURGE LOG?'),
        content: const Text('This action will permanently delete this attendance record. Access will be reset for the personnel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              final provider = Provider.of<AttendanceProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await provider.clearMemberStatus(record.userId, record.date);
                setState(() {});
                if (mounted) {
                   messenger.showSnackBar(
                     const SnackBar(content: Text('RECORD PURGED'), backgroundColor: Colors.black),
                   );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('CONFIRM PURGE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    
    return FutureBuilder<SalarySummary?>(
      future: provider.getSalarySummary(widget.user, _selectedDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = snapshot.data!;
        
        return AnimatedEntrance(
          delay: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NET SALARY PROJECTION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('AED ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black45)),
                          AnimatedCount(
                            count: summary.netSalary.toInt(),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on ${summary.presentDays} active sessions this month',
                        style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 100, color: Colors.black.withOpacity(0.05)),
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEDUCTION BREAKDOWN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 2),
                      ),
                      const SizedBox(height: 24),
                      _deductionRow('Late Arrivals', summary.lateDeductions),
                      const SizedBox(height: 12),
                      _deductionRow('Break Intervals', summary.lunchDeductions),
                      const SizedBox(height: 12),
                      const Divider(height: 12),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL LOSS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          Text(
                            'AED ${summary.totalDeductions.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _deductionRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500)),
        Text('AED ${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black)),
      ],
    );
  }
}
