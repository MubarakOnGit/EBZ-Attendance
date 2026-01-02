import 'package:flutter/material.dart';
import '../../models/app_rules.dart';
import '../../services/firestore_service.dart';

class RulesConfigScreen extends StatefulWidget {
  const RulesConfigScreen({super.key});

  @override
  State<RulesConfigScreen> createState() => _RulesConfigScreenState();
}

class _RulesConfigScreenState extends State<RulesConfigScreen> {
  final _firestoreService = FirestoreService();
  final _ssidController = TextEditingController();
  final _graceController = TextEditingController();
  final _deductionController = TextEditingController();

  AppRules? _rules;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final rules = await _firestoreService.getRules();
    setState(() {
      _rules = rules ?? AppRules(
        allowedSsids: [],
        allowedBssids: [],
        gracePeriodMinutes: 5,
        deductionPerMinute: 1.0,
        officeStartTime: const TimeOfDay(hour: 9, minute: 0),
        officeEndTime: const TimeOfDay(hour: 18, minute: 0),
        lunchStartTime: const TimeOfDay(hour: 13, minute: 0),
        lunchEndTime: const TimeOfDay(hour: 14, minute: 0),
        weeklySchedule: {},
      );
      _graceController.text = _rules!.gracePeriodMinutes.toString();
      _deductionController.text = _rules!.deductionPerMinute.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveRules() async {
    if (_rules != null) {
      final updatedRules = AppRules(
        allowedSsids: _rules!.allowedSsids,
        allowedBssids: _rules!.allowedBssids,
        gracePeriodMinutes: int.tryParse(_graceController.text) ?? 5,
        deductionPerMinute: double.tryParse(_deductionController.text) ?? 1.0,
        officeStartTime: _rules!.officeStartTime,
        officeEndTime: _rules!.officeEndTime,
        lunchStartTime: _rules!.lunchStartTime,
        lunchEndTime: _rules!.lunchEndTime,
        weeklySchedule: _rules!.weeklySchedule,
      );
      await _firestoreService.saveRules(updatedRules);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings updated successfully!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _addSsid() {
    if (_ssidController.text.isNotEmpty) {
      setState(() {
        _rules!.allowedSsids.add(_ssidController.text);
        _ssidController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
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
                    'Attendance Settings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Configure WiFi restrictions and salary deduction rules', 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveRules,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildSection(
                    title: 'WiFi Restrictions',
                    description: 'Members must be connected to these SSIDs to check-in.',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ssidController,
                                decoration: InputDecoration(
                                  hintText: 'Work_WiFi_Main',
                                  filled: true,
                                  fillColor: Colors.blueGrey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filled(
                              onPressed: _addSsid,
                              icon: const Icon(Icons.add_rounded),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _rules!.allowedSsids.map((ssid) => Chip(
                            label: Text(ssid, style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.blueAccent.withOpacity(0.05),
                            side: BorderSide(color: Colors.blueAccent.withOpacity(0.1)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            onDeleted: () => setState(() => _rules!.allowedSsids.remove(ssid)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Deduction Rules',
                    description: 'Set late-arrival grace periods and penalty rates.',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                    child: Column(
                      children: [
                        _buildInputField(
                          label: 'Grace Period (Minutes)',
                          controller: _graceController,
                          icon: Icons.timer_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Penalty Rate (per min)',
                          controller: _deductionController,
                          icon: Icons.money_off_csred_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String description, required Widget child, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.blueGrey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.blueGrey[400], fontSize: 13)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.blueGrey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
