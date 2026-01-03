import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_account.dart';
import '../../services/firestore_service.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/salary_calculator.dart';
import '../../widgets/animated_count.dart';
import 'add_member_screen.dart';
import 'member_details_screen.dart';

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

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
                  const Text(
                    'Personnel Directory',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text('Manage your operational staff and their active credentials.', 
                    style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen())),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('ONBOARD PERSONNEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Expanded(
            child: StreamBuilder<List<UserAccount>>(
              stream: firestoreService.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return _buildEmptyState();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 32,
                        mainAxisSpacing: 32,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _buildMemberCard(context, member);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, UserAccount member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailsScreen(user: member),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      member.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${member.employeeId.toUpperCase()}',
                      style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                     const SizedBox(height: 12),
                    _buildMonthlyQuickStats(context, member),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black.withOpacity(0.1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyQuickStats(BuildContext context, UserAccount member) {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    
    return FutureBuilder<SalarySummary?>(
      future: provider.getSalarySummary(member, DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = snapshot.data!;
        final hasDeductions = summary.totalDeductions > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statBadge(
                  label: 'NET: AED ${summary.netSalary.toInt()}',
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                if (hasDeductions)
                  _statBadge(
                    label: '-AED ${summary.totalDeductions.toInt()}',
                    color: Colors.redAccent,
                  )
                else
                  _statBadge(
                    label: 'PERFECT',
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('No personnel records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.2))),
        ],
      ),
    );
  }
}
