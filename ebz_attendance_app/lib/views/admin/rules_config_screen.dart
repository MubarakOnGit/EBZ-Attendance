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
  final _lunchLimitController = TextEditingController();

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
        isWifiRestrictionEnabled: false,
        isOvertimeEnabled: false,
        isDeductionEnabled: false,
        isLunchDeductionEnabled: false,
        lunchLimitMinutes: 60,
        weeklySchedule: {},
      );
      _graceController.text = _rules!.gracePeriodMinutes.toString();
      _deductionController.text = _rules!.deductionPerMinute.toString();
      _lunchLimitController.text = _rules!.lunchLimitMinutes.toString();
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
        lunchLimitMinutes: int.tryParse(_lunchLimitController.text) ?? 60,
        officeStartTime: _rules!.officeStartTime,
        officeEndTime: _rules!.officeEndTime,
        lunchStartTime: _rules!.lunchStartTime,
        lunchEndTime: _rules!.lunchEndTime,
        isWifiRestrictionEnabled: _rules!.isWifiRestrictionEnabled,
        isOvertimeEnabled: _rules!.isOvertimeEnabled,
        isDeductionEnabled: _rules!.isDeductionEnabled,
        isLunchDeductionEnabled: _rules!.isLunchDeductionEnabled,
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
                    'Operational Rules',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Configure office protocols, compliance metrics, and payroll logic.', 
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveRules,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Update Protocols'),
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  _buildSection(
                    title: 'Core Schedule',
                    description: 'Define standard operating hours and mandatory break intervals.',
                    width: isWide ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth,
                    child: Column(
                      children: [
                        _buildTimeRow('Operational Hours', _rules!.officeStartTime, _rules!.officeEndTime, (start, end) {
                          setState(() {
                            _rules = _copyRulesWith(officeStartTime: start, officeEndTime: end);
                          });
                        }),
                        const SizedBox(height: 40),
                        _buildTimeRow('Rest Interval', _rules!.lunchStartTime, _rules!.lunchEndTime, (start, end) {
                          setState(() {
                            _rules = _copyRulesWith(lunchStartTime: start, lunchEndTime: end);
                          });
                        }),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Network Compliance',
                    description: 'Restrict operational access to authorized corporate networks.',
                    width: isWide ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.black,
                            title: const Text('Network Validation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Verify SSID presence during authentication', style: TextStyle(fontSize: 12)),
                            value: _rules!.isWifiRestrictionEnabled,
                            onChanged: (val) => setState(() => _rules = _copyRulesWith(isWifiRestrictionEnabled: val)),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                              child: TextField(
                                controller: _ssidController,
                                decoration: InputDecoration(
                                  hintText: 'Authorized SSID',
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _addSsid,
                              icon: const Icon(Icons.add_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _rules!.allowedSsids.map((ssid) => Chip(
                            label: Text(ssid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            backgroundColor: Colors.black,
                            labelStyle: const TextStyle(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                            onDeleted: () => setState(() => _rules!.allowedSsids.remove(ssid)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Payroll & Adjustments',
                    description: 'Configure automated overtime tracking and late-arrival penalties.',
                    width: isWide ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth,
                    child: Column(
                      children: [
                        _buildSwitch('Deduction Engine', 'Automate penalties for tardiness', _rules!.isDeductionEnabled, (val) => setState(() => _rules = _copyRulesWith(isDeductionEnabled: val))),
                        _buildSwitch('Overtime Analytics', 'Record operational hours beyond shift end', _rules!.isOvertimeEnabled, (val) => setState(() => _rules = _copyRulesWith(isOvertimeEnabled: val))),
                        _buildSwitch('Break Compliance', 'Flag intervals exceeding mandatory limits', _rules!.isLunchDeductionEnabled, (val) => setState(() => _rules = _copyRulesWith(isLunchDeductionEnabled: val))),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Grace Offset (M)', controller: _graceController, icon: Icons.timer_outlined)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildInputField(label: 'Max Break (M)', controller: _lunchLimitController, icon: Icons.restaurant_rounded)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(label: 'Adjustment Rate (Per Minute)', controller: _deductionController, icon: Icons.money_off_csred_rounded),
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

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.black,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  AppRules _copyRulesWith({
    TimeOfDay? officeStartTime,
    TimeOfDay? officeEndTime,
    TimeOfDay? lunchStartTime,
    TimeOfDay? lunchEndTime,
    bool? isWifiRestrictionEnabled,
    bool? isOvertimeEnabled,
    bool? isDeductionEnabled,
    bool? isLunchDeductionEnabled,
  }) {
    return AppRules(
      allowedSsids: _rules!.allowedSsids,
      allowedBssids: _rules!.allowedBssids,
      gracePeriodMinutes: _rules!.gracePeriodMinutes,
      deductionPerMinute: _rules!.deductionPerMinute,
      officeStartTime: officeStartTime ?? _rules!.officeStartTime,
      officeEndTime: officeEndTime ?? _rules!.officeEndTime,
      lunchStartTime: lunchStartTime ?? _rules!.lunchStartTime,
      lunchEndTime: lunchEndTime ?? _rules!.lunchEndTime,
      isWifiRestrictionEnabled: isWifiRestrictionEnabled ?? _rules!.isWifiRestrictionEnabled,
      isOvertimeEnabled: isOvertimeEnabled ?? _rules!.isOvertimeEnabled,
      isDeductionEnabled: isDeductionEnabled ?? _rules!.isDeductionEnabled,
      isLunchDeductionEnabled: isLunchDeductionEnabled ?? _rules!.isLunchDeductionEnabled,
      lunchLimitMinutes: _rules!.lunchLimitMinutes,
      weeklySchedule: _rules!.weeklySchedule,
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay start, TimeOfDay end, Function(TimeOfDay, TimeOfDay) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.black26)),
        const SizedBox(height: 20),
        Row(
          children: [
            _timeChip(context, start, (t) => onUpdate(t, end)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('→', style: TextStyle(color: Colors.black26))),
            _timeChip(context, end, (t) => onUpdate(start, t)),
          ],
        ),
      ],
    );
  }

  Widget _timeChip(BuildContext context, TimeOfDay time, Function(TimeOfDay) onSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(time.format(context).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildSection({required String title, required String description, required Widget child, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13)),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1, color: Colors.black26)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.black),
            filled: true,
            fillColor: Colors.black.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
