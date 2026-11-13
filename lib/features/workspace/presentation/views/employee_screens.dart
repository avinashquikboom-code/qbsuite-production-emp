import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../data/production_api.dart';
import '../providers/production_providers.dart';

final salaryTargetProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ref.watch(productionApiProvider).salaryTarget();
  } catch (_) {
    return const {};
  }
});

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _designation = TextEditingController();
  final _department = TextEditingController();
  bool _saving = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(employeeProfileProvider).asData?.value ?? const {};
    final name = '${data['name'] ?? ''}'.trim();
    final parts = name.split(RegExp(r'\s+'));
    _first.text = '${data['firstName'] ?? (parts.isEmpty ? '' : parts.first)}';
    _last.text = '${data['lastName'] ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '')}';
    _email.text = '${data['email'] ?? ''}';
    _phone.text = '${data['phone'] ?? ''}';
    _designation.text = '${data['designation'] ?? ''}';
    _department.text = '${data['department'] ?? ''}';
    _ready = true;
  }

  @override
  void dispose() {
    for (final controller in [_first, _last, _email, _phone, _designation, _department]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(productionApiProvider).updateProfile({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim().isEmpty ? _first.text.trim() : _last.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      });
      ref.invalidate(employeeProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = '${_first.text} ${_last.text}'.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).map((part) => part[0]).take(2).join().toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: AppTypography.inter(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
          ),
        ],
      ),
      body: _ready
          ? Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary,
                          child: Text(initials.isEmpty ? 'EM' : initials, style: AppTypography.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 10),
                        Text('Profile photo is managed by HR', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _label('Personal Information'),
                  const SizedBox(height: 12),
                  _field(_first, 'First Name', Remix.user_3_line, requiredField: true),
                  const SizedBox(height: 14),
                  _field(_last, 'Last Name', Remix.user_3_line),
                  const SizedBox(height: 14),
                  _field(_email, 'Work Email', Remix.mail_line, readOnly: true, helper: 'Contact HR to update your email'),
                  const SizedBox(height: 14),
                  _field(_phone, 'Mobile Number', Remix.smartphone_line, type: TextInputType.phone, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))]),
                  const SizedBox(height: 28),
                  _label('Work Details'),
                  const SizedBox(height: 12),
                  _field(_designation, 'Designation', Remix.briefcase_line, readOnly: true, helper: 'Contact HR to update your designation'),
                  const SizedBox(height: 14),
                  _field(_department, 'Department', Remix.building_line, readOnly: true, helper: 'Contact HR to update your department'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Remix.save_line, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Save Changes', style: AppTypography.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _label(String text) => Text(text.toUpperCase(), style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2));

  Widget _field(TextEditingController controller, String label, IconData icon, {bool readOnly = false, bool requiredField = false, bool obscure = false, String? helper, TextInputType? type, List<TextInputFormatter>? formatters}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      keyboardType: type,
      inputFormatters: formatters,
      style: AppTypography.inter(fontSize: 14),
      validator: requiredField ? (value) => value == null || value.trim().isEmpty ? '$label is required' : null : null,
      decoration: InputDecoration(labelText: label, helperText: helper, prefixIcon: Icon(icon, color: AppColors.primary, size: 20)),
    );
  }
}

class LeaveApplicationsScreen extends ConsumerStatefulWidget {
  const LeaveApplicationsScreen({super.key});

  @override
  ConsumerState<LeaveApplicationsScreen> createState() => _LeaveApplicationsScreenState();
}

class _LeaveApplicationsScreenState extends ConsumerState<LeaveApplicationsScreen> {
  String _filter = 'Active';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _balances = const [];
  List<Map<String, dynamic>> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(productionApiProvider);
      final results = await Future.wait([api.leaveBalances(), api.leaveRequests()]);
      _balances = results[0];
      _requests = results[1];
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _upcoming(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return true;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    return !DateTime(date.year, date.month, date.day).isBefore(day);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _requests.where((row) {
      final status = '${row['status'] ?? ''}'.toUpperCase();
      final active = status == 'PENDING' || (status == 'APPROVED' && _upcoming('${row['toDate'] ?? ''}'));
      return _filter == 'Active' ? active : !active;
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Requests & Leaves', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _requests.isEmpty
          ? _retry(_error!, _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var index = 0; index < _balances.length; index++)
                        SizedBox(
                          width: (MediaQuery.sizeOf(context).width - 50) / 2,
                          child: _balanceCard(_balances[index], index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Leave Applications', style: AppTypography.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      FilledButton.icon(onPressed: _applyLeave, icon: const Icon(Remix.add_line, size: 16), label: const Text('Apply')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _segment(_filter, (value) => setState(() => _filter = value)),
                  const SizedBox(height: 16),
                  if (visible.isEmpty) _empty('No $_filter leave applications') else for (final row in visible) _leaveCard(row),
                ],
              ),
            ),
    );
  }

  Widget _balanceCard(Map<String, dynamic> row, int index) {
    const colors = [AppColors.primary, Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF6366F1)];
    final color = colors[index % colors.length];
    final unlimited = row['isUnlimited'] == true;
    final remaining = unlimited ? '∞' : '${num.tryParse('${row['remaining'] ?? row['balance'] ?? 0}')?.toInt() ?? 0}';
    final total = unlimited ? 'Unlimited' : '${num.tryParse('${row['totalAllowed'] ?? row['allocated'] ?? 0}')?.toInt() ?? 0} Total';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${row['leaveType'] ?? row['name'] ?? 'Leave'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(remaining, style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(total, style: AppTypography.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _leaveCard(Map<String, dynamic> row) {
    final status = '${row['status'] ?? 'PENDING'}'.toUpperCase();
    final days = num.tryParse('${row['days'] ?? row['totalDays'] ?? 1}') ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${row['leaveType'] ?? 'Leave'}', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 15))),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Remix.calendar_event_line, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text('${_day(row['fromDate'])} to ${_day(row['toDate'])} • ${days == 1 ? '1 day' : '$days days'}', style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary))),
            ],
          ),
          if ('${row['appliedOn'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Applied: ${_day(row['appliedOn'])}', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if ('${row['reason'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${row['reason']}', style: AppTypography.inter(fontSize: 13)),
          ],
          if (status == 'REJECTED' && '${row['rejectionReason'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text('Reason: ${row['rejectionReason']}', style: AppTypography.inter(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _applyLeave() async {
    final types = _balances.isNotEmpty ? _balances : await ref.read(productionApiProvider).leaveTypes();
    if (!mounted) return;
    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No leave types are available.')));
      return;
    }
    var typeId = types.isEmpty ? 1 : int.tryParse('${types.first['leaveTypeId'] ?? types.first['id']}') ?? 1;
    var from = DateTime.now();
    var to = DateTime.now().add(const Duration(days: 1));
    final reason = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply for Leave', style: AppTypography.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: typeId,
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                  items: types.map((item) {
                    final id = int.tryParse('${item['leaveTypeId'] ?? item['id']}') ?? typeId;
                    return DropdownMenuItem(value: id, child: Text('${item['leaveType'] ?? item['name'] ?? 'Leave'}'));
                  }).toList(),
                  onChanged: (value) { if (value != null) setSheet(() => typeId = value); },
                ),
                const SizedBox(height: 14),
                _dateButton(context, 'From Date', from, (value) => setSheet(() { from = value; if (to.isBefore(from)) to = from; })),
                const SizedBox(height: 10),
                _dateButton(context, 'To Date', to, (value) => setSheet(() => to = value)),
                const SizedBox(height: 14),
                TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason for Leave *')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (reason.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason.')));
                        return;
                      }
                      Navigator.pop(sheet, true);
                    },
                    child: const Text('Submit Leave Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (saved != true) return;
    try {
      await ref.read(productionApiProvider).applyLeave({
        'leaveTypeId': typeId,
        'fromDate': from.toIso8601String().split('T').first,
        'toDate': to.toIso8601String().split('T').first,
        'days': to.difference(from).inDays + 1,
        'reason': text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted (Status: PENDING).')));
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class RemoteWorkScreen extends ConsumerStatefulWidget {
  const RemoteWorkScreen({super.key});

  @override
  ConsumerState<RemoteWorkScreen> createState() => _RemoteWorkScreenState();
}

class _RemoteWorkScreenState extends ConsumerState<RemoteWorkScreen> {
  String _filter = 'ACTIVE';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _rows = await ref.read(productionApiProvider).remoteRequests();
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _rows.where((row) {
      final status = '${row['status'] ?? ''}'.toUpperCase();
      return switch (_filter) {
        'APPROVED' => status == 'APPROVED',
        'PENDING' => status == 'PENDING',
        'ACTIVE' => status == 'APPROVED' || status == 'PENDING',
        _ => true,
      };
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Remote Work (WFH)', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _apply,
        icon: const Icon(Remix.add_line),
        label: Text('Apply WFH', style: AppTypography.inter(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Active', 'ACTIVE'),
                _chip('Approved', 'APPROVED'),
                _chip('Pending', 'PENDING'),
                _chip('All History', 'HISTORY'),
              ]),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _rows.isEmpty
                ? _retry(_error!, _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: visible.isEmpty
                        ? ListView(children: [_empty('No remote work requests')])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                            itemCount: visible.length,
                            itemBuilder: (_, index) => _card(visible[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.lightPrimary,
        checkmarkColor: AppColors.darkPrimary,
        labelStyle: AppTypography.inter(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.darkPrimary : AppColors.textPrimary),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _card(Map<String, dynamic> row) {
    final status = '${row['status'] ?? 'PENDING'}'.toUpperCase();
    final days = num.tryParse('${row['days'] ?? 1}')?.toInt() ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Remix.calendar_event_line, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text('${_day(row['fromDate'])} - ${_day(row['toDate'])}', style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700))),
              _statusPill(status),
            ],
          ),
          if ('${row['startTime'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${row['startTime']} – ${row['endTime'] ?? ''}', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
          if ('${row['reason'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${row['reason']}', style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
          ],
          const SizedBox(height: 12),
          Text('Duration: $days ${days == 1 ? 'day' : 'days'}', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    var from = DateTime.now();
    var to = DateTime.now();
    var start = const TimeOfDay(hour: 9, minute: 0);
    var end = const TimeOfDay(hour: 18, minute: 0);
    final reason = TextEditingController();
    String clock(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      return '${hour.toString().padLeft(2, '0')}:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Apply for Remote Work (WFH)', style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _dateButton(context, 'From Date', from, (value) => setSheet(() { from = value; if (to.isBefore(from)) to = from; }))),
                  const SizedBox(width: 12),
                  Expanded(child: _dateButton(context, 'To Date', to, (value) => setSheet(() => to = value))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _timeButton('Start Time', clock(start), () async {
                    final picked = await showTimePicker(context: context, initialTime: start);
                    if (picked != null) setSheet(() => start = picked);
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _timeButton('End Time', clock(end), () async {
                    final picked = await showTimePicker(context: context, initialTime: end);
                    if (picked != null) setSheet(() => end = picked);
                  })),
                ]),
                const SizedBox(height: 14),
                Text('Reason & Deliverables Plan *', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(hintText: 'Explain reason and planned deliverables during remote work...')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (reason.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason.')));
                        return;
                      }
                      Navigator.pop(sheet, true);
                    },
                    child: const Text('SUBMIT APPLICATION'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (saved != true) return;
    try {
      await ref.read(productionApiProvider).applyRemote({
        'fromDate': from.toIso8601String().split('T').first,
        'toDate': to.toIso8601String().split('T').first,
        'startTime': clock(start),
        'endTime': clock(end),
        'days': to.difference(from).inDays + 1,
        'reason': text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remote work request submitted.')));
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class ExpensesClaimsScreen extends ConsumerStatefulWidget {
  const ExpensesClaimsScreen({super.key});

  @override
  ConsumerState<ExpensesClaimsScreen> createState() => _ExpensesClaimsScreenState();
}

class _ExpensesClaimsScreenState extends ConsumerState<ExpensesClaimsScreen> {
  static const _categories = ['TRAVEL', 'FOOD', 'FUEL', 'ACCOMMODATION', 'OFFICE_SUPPLIES', 'MEDICAL', 'CLIENT_ENTERTAINMENT', 'OTHER'];
  String _filter = 'Active';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _rows = await ref.read(productionApiProvider).claims();
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _active(Map<String, dynamic> row) {
    final status = '${row['status'] ?? ''}'.toUpperCase();
    return status == 'PENDING' || status == 'APPROVED';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _rows.where((row) => _filter == 'Active' ? _active(row) : !_active(row)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Expenses & Claims', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Remix.refresh_line))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _rows.isEmpty
          ? _retry(_error!, _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Expense Claims', style: AppTypography.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                      FilledButton.icon(onPressed: _apply, icon: const Icon(Remix.add_line, size: 16), label: const Text('New Claim')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _segment(_filter, (value) => setState(() => _filter = value)),
                  const SizedBox(height: 14),
                  if (visible.isEmpty) _empty('No $_filter expense claims') else for (final row in visible) _claimCard(row),
                ],
              ),
            ),
    );
  }

  Widget _claimCard(Map<String, dynamic> row) {
    final status = '${row['status'] ?? 'PENDING'}'.toUpperCase();
    final amount = num.tryParse('${row['amount'] ?? 0}') ?? 0;
    final approved = num.tryParse('${row['approvedAmount'] ?? ''}');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${row['category'] ?? 'Claim'}'.replaceAll('_', ' '), style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 15))),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Claimed: ${AppCurrency.format(amount)}', style: AppTypography.inter(fontWeight: FontWeight.w700, color: AppColors.darkPrimary)),
          if (approved != null) Text('Approved: ${AppCurrency.format(approved)}', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
          if ('${row['description'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${row['description']}', style: AppTypography.inter(fontSize: 13)),
          ],
          if ('${row['claimDate'] ?? ''}'.isNotEmpty) Text(_day(row['claimDate']), style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
          if ('${row['rejectionReason'] ?? ''}'.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('Reason: ${row['rejectionReason']}', style: AppTypography.inter(fontSize: 12, color: AppColors.danger))),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    var category = _categories.first;
    var date = DateTime.now();
    final amount = TextEditingController();
    final description = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New expense claim', style: AppTypography.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Expense category'),
                  items: _categories.map((item) => DropdownMenuItem(value: item, child: Text(item.replaceAll('_', ' ')))).toList(),
                  onChanged: (value) { if (value != null) setSheet(() => category = value); },
                ),
                const SizedBox(height: 12),
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
                const SizedBox(height: 12),
                _dateButton(context, 'Claim date', date, (value) => setSheet(() => date = value)),
                const SizedBox(height: 12),
                TextField(controller: description, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final value = num.tryParse(amount.text.trim());
                      if (value == null || value < 1 || description.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount of at least ₹1 and a description.')));
                        return;
                      }
                      Navigator.pop(sheet, true);
                    },
                    child: Text('Submit claim', style: AppTypography.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final value = num.tryParse(amount.text.trim());
    final text = description.text.trim();
    amount.dispose();
    description.dispose();
    if (saved != true || value == null) return;
    try {
      await ref.read(productionApiProvider).applyClaim({
        'category': category,
        'amount': value,
        'description': text,
        'claimDate': date.toIso8601String().split('T').first,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense claim submitted.')));
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}


class SalarySlipsScreen extends ConsumerWidget {
  const SalarySlipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slips = ref.watch(payslipsProvider);
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? const {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Salary Slips & Payroll', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [IconButton(onPressed: () => ref.invalidate(payslipsProvider), icon: const Icon(Remix.refresh_line))],
      ),
      body: slips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _retry(error, () => ref.invalidate(payslipsProvider)),
        data: (items) {
          final latest = items.isEmpty ? null : items.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              if (latest != null) ...[
                _latestCard(context, latest),
                const SizedBox(height: 14),
              ],
              Builder(builder: (context) {
                final target = ref.watch(salaryTargetProvider).asData?.value;
                if (target == null || target.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _infoCard('Target Salary', [
                    _line('Monthly target', AppCurrency.format(num.tryParse('${target['monthlyTarget'] ?? 0}') ?? 0)),
                    _line('Achieved', AppCurrency.format(num.tryParse('${target['achievedAmount'] ?? 0}') ?? 0)),
                    _line('Eligible salary', AppCurrency.format(num.tryParse('${target['eligibleSalary'] ?? 0}') ?? 0)),
                    _line('Status', '${target['targetStatus'] ?? '—'}'),
                  ]),
                );
              }),
              _infoCard('Employee Information', [
                _line('Name', '${profile['name'] ?? ''}'),
                _line('Code', '${profile['employeeCode'] ?? ''}'),
                _line('Designation', '${profile['designation'] ?? ''}'),
                _line('Department', '${profile['department'] ?? ''}'),
              ]),
              const SizedBox(height: 14),
              _infoCard('Bank & Payment', [
                _line('Account', _mask('${_bank(profile)['accountNumber'] ?? _bank(profile)['accountNo'] ?? ''}')),
                _line('Bank', '${_bank(profile)['bankName'] ?? _bank(profile)['bank'] ?? '—'}'),
                _line('IFSC', '${_bank(profile)['ifsc'] ?? _bank(profile)['ifscCode'] ?? '—'}'),
              ]),
              const SizedBox(height: 24),
              Text('Payslip History', style: AppTypography.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (items.isEmpty) _empty('No salary slips yet') else for (final slip in items) _historyTile(context, slip),
            ],
          );
        },
      ),
    );
  }

  Widget _latestCard(BuildContext context, Map<String, dynamic> slip) {
    final net = num.tryParse('${slip['netSalary'] ?? slip['netPay'] ?? slip['amount'] ?? 0}') ?? 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PayslipScreen(slip: slip))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0F763E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LATEST SALARY SLIP', style: AppTypography.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Text('${slip['month'] ?? slip['period'] ?? 'Payslip'}', style: AppTypography.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(AppCurrency.format(net), style: AppTypography.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Tap to open the payslip', style: AppTypography.inter(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(BuildContext context, Map<String, dynamic> slip) {
    final net = num.tryParse('${slip['netSalary'] ?? slip['netPay'] ?? slip['amount'] ?? 0}') ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${slip['month'] ?? slip['period'] ?? 'Payslip'}', style: AppTypography.inter(fontWeight: FontWeight.w700)),
      subtitle: Text('${slip['status'] ?? 'GENERATED'}', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Text(AppCurrency.format(net), style: AppTypography.inter(fontWeight: FontWeight.w700)),
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PayslipScreen(slip: slip))),
    );
  }
}

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key, required this.slip});
  final Map<String, dynamic> slip;

  @override
  Widget build(BuildContext context) {
    final earnings = _rows(slip['earnings'] ?? slip['allowances']);
    final deductions = _rows(slip['deductions']);
    final gross = num.tryParse('${slip['grossSalary'] ?? slip['grossPay'] ?? 0}') ?? 0;
    final net = num.tryParse('${slip['netSalary'] ?? slip['netPay'] ?? slip['amount'] ?? 0}') ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Payslip', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QB SUITE', style: AppTypography.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text('${slip['month'] ?? slip['period'] ?? ''}', style: AppTypography.inter(color: AppColors.textSecondary)),
                const Divider(height: 24),
                Text('Earnings', style: AppTypography.inter(fontWeight: FontWeight.w700)),
                if (earnings.isEmpty) _line('Gross', AppCurrency.format(gross)) else for (final row in earnings) _line(row.$1, AppCurrency.format(row.$2)),
                const SizedBox(height: 12),
                Text('Deductions', style: AppTypography.inter(fontWeight: FontWeight.w700)),
                if (deductions.isEmpty) _line('Deductions', AppCurrency.format(gross - net)) else for (final row in deductions) _line(row.$1, AppCurrency.format(row.$2)),
                const Divider(height: 24),
                _line('Net Pay', AppCurrency.format(net)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, num)> _rows(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final label = '${item['name'] ?? item['label'] ?? item['component'] ?? 'Item'}';
      final amount = num.tryParse('${item['amount'] ?? item['value'] ?? 0}') ?? 0;
      return (label, amount);
    }).toList();
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Account Settings', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('Profile & Security'),
          _group([
            _tile(context, 'Profile Information', 'Edit your name, email and phone', Remix.user_3_line, const EditProfileScreen()),
            _tile(context, 'Change Password', 'Update your account password', Remix.lock_2_line, const ChangePasswordScreen()),
          ]),
          const SizedBox(height: 28),
          _header('Preferences'),
          _group([
            _tile(context, 'Notifications', 'Manage app alerts', Remix.notification_3_line, null),
            _tile(context, 'Language', 'English (US)', Remix.translate_2, null),
          ]),
          const SizedBox(height: 28),
          _header('About'),
          _group([
            _tile(context, 'App Version', 'v1.0.0', Remix.information_line, null, trailing: false),
          ]),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(title.toUpperCase(), style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
  );

  Widget _group(List<Widget> children) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );

  Widget _tile(BuildContext context, String title, String subtitle, IconData icon, Widget? page, {bool trailing = true}) {
    return ListTile(
      onTap: page == null ? null : () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: trailing ? const Icon(Remix.arrow_right_s_line, size: 18) : null,
    );
  }
}

Widget _line(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Expanded(child: Text(label, style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary))),
      Text(value.isEmpty ? '—' : value, style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  ),
);

Widget _infoCard(String title, List<Widget> lines) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppTypography.inter(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    ...lines,
  ]),
);

Map _bank(Map profile) => profile['bankDetails'] is Map ? profile['bankDetails'] as Map : const {};

String _mask(String raw) {
  final clean = raw.trim();
  if (clean.length <= 4) return clean.isEmpty ? '—' : clean;
  return 'XXXX XXXX ${clean.substring(clean.length - 4)}';
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(productionApiProvider).changePassword({
        'currentPassword': _current.text,
        'newPassword': _next.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Change Password', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Update your account password', style: AppTypography.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Remix.lock_2_line)),
              validator: (value) => value == null || value.isEmpty ? 'Current password is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Remix.lock_password_line),
                helperText: 'At least 12 characters with upper, lower, number and symbol',
              ),
              validator: (value) => value == null || value.length < 12 ? 'Use at least 12 characters' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Remix.lock_password_line)),
              validator: (value) => value != _next.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Update Password', style: AppTypography.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _segment(String selected, ValueChanged<String> onSelect) {
  Widget button(String title, String value) {
    final active = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(title, style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [button('Active / Pending', 'Active'), button('History', 'History')]),
  );
}

Widget _statusPill(String status) {
  final color = status == 'APPROVED' || status == 'PAID'
      ? AppColors.primary
      : status == 'REJECTED'
      ? AppColors.danger
      : const Color(0xFFD97706);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(status, style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
  );
}

String _day(Object? value) {
  final text = '${value ?? ''}'.split('T').first;
  return text.isEmpty ? '—' : text;
}

Widget _dateButton(BuildContext context, String label, DateTime value, ValueChanged<DateTime> onPick) {
  return OutlinedButton.icon(
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime.now().subtract(const Duration(days: 180)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) onPick(picked);
    },
    icon: const Icon(Remix.calendar_line, size: 15),
    label: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.inter(fontSize: 11)),
        Text('${value.day}/${value.month}/${value.year}', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

Widget _timeButton(String label, String value, VoidCallback onTap) {
  return OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Remix.time_line, size: 15),
    label: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.inter(fontSize: 11)),
        Text(value, style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

Widget _empty(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 28),
  child: Center(child: Text(text, style: AppTypography.inter(color: AppColors.textSecondary))),
);

Widget _retry(Object error, VoidCallback onRetry) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$error', textAlign: TextAlign.center, style: AppTypography.inter(color: AppColors.textSecondary)),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  ),
);
