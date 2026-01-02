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
                  const Text('Configure office hours, lunch breaks, and penalty rules', 
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
                    title: 'Office Hours',
                    description: 'Set standard working and lunch times.',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                    child: Column(
                      children: [
                        _buildTimeRow('Work Hours', _rules!.officeStartTime, _rules!.officeEndTime, (start, end) {
                          setState(() {
                            _rules = _copyRulesWith(officeStartTime: start, officeEndTime: end);
                          });
                        }),
                        const Divider(height: 32),
                        _buildTimeRow('Lunch Break', _rules!.lunchStartTime, _rules!.lunchEndTime, (start, end) {
                          setState(() {
                            _rules = _copyRulesWith(lunchStartTime: start, lunchEndTime: end);
                          });
                        }),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'WiFi Restrictions',
                    description: 'Members must be connected to these SSIDs to check-in.',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable WiFi Restriction', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Validate connection during check-in'),
                            value: _rules!.isWifiRestrictionEnabled,
                            onChanged: (val) => setState(() => _rules = _copyRulesWith(isWifiRestrictionEnabled: val)),
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
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
                    title: 'Payroll Logic',
                    description: 'Automate overtime and late-arrival deductions.',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Deductions', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Apply penalties for late arrivals'),
                          value: _rules!.isDeductionEnabled,
                          onChanged: (val) => setState(() => _rules = _copyRulesWith(isDeductionEnabled: val)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Overtime', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Record hours worked beyond shift end'),
                          value: _rules!.isOvertimeEnabled,
                          onChanged: (val) => setState(() => _rules = _copyRulesWith(isOvertimeEnabled: val)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Strict Lunch Hour', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Deduct salary if break exceeds limit'),
                          value: _rules!.isLunchDeductionEnabled,
                          onChanged: (val) => setState(() => _rules = _copyRulesWith(isLunchDeductionEnabled: val)),
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Late Grace (Min)', controller: _graceController, icon: Icons.timer_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInputField(label: 'Lunch Max (Min)', controller: _lunchLimitController, icon: Icons.restaurant_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(label: 'Penalty Rate (per min/hourly)', controller: _deductionController, icon: Icons.money_off_csred_rounded),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _timeChip(context, start, (t) => onUpdate(t, end)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
                  _timeChip(context, end, (t) => onUpdate(start, t)),
                ],
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: Colors.blueGrey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
  }
}
