import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_account.dart';
import '../../models/attendance_record.dart';

class TopPerformersWidget extends StatelessWidget {
  const TopPerformersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Efficiency Leaderboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personnel with perfect punctuality metrics.',
            style: TextStyle(fontSize: 11, color: Colors.black26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 40),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').where('role', isEqualTo: 1).limit(5).snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final members = userSnapshot.data!.docs.map((doc) => UserAccount.fromMap(doc.data() as Map<String, dynamic>)).toList();

              return Column(
                children: members.asMap().entries.map((entry) {
                  return _PerformerRow(index: entry.key, member: entry.value);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PerformerRow extends StatefulWidget {
  final int index;
  final UserAccount member;

  const _PerformerRow({required this.index, required this.member});

  @override
  State<_PerformerRow> createState() => _PerformerRowState();
}

class _PerformerRowState extends State<_PerformerRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.black.withOpacity(0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        transform: _isHovered 
          ? (Matrix4.identity()..translate(8.0, 0.0)) 
          : Matrix4.identity(),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(widget.index == 0 ? 1 : (_isHovered ? 0.1 : 0.05)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: widget.index == 0 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Text(
                    'ID: ${widget.member.employeeId.toUpperCase()}',
                    style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const Text(
              '100%',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
