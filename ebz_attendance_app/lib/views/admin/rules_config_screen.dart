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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rules saved!')));
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Rules')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('WiFi Restrictions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ssidController,
                    decoration: const InputDecoration(labelText: 'Add SSID'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addSsid),
              ],
            ),
            Wrap(
              children: _rules!.allowedSsids.map((ssid) => Chip(
                label: Text(ssid),
                onDeleted: () => setState(() => _rules!.allowedSsids.remove(ssid)),
              )).toList(),
            ),
            const Divider(height: 32),
            const Text('Deduction Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _graceController,
              decoration: const InputDecoration(labelText: 'Grace Period (minutes)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deductionController,
              decoration: const InputDecoration(labelText: 'Deduction per Minute (Late/Early)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveRules,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
