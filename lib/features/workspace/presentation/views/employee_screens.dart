import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../data/production_api.dart';
import '../providers/production_providers.dart';

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


class SalarySlipsScreen extends ConsumerStatefulWidget {
  const SalarySlipsScreen({super.key});

  @override
  ConsumerState<SalarySlipsScreen> createState() => _SalarySlipsScreenState();
}

class _SalarySlipsScreenState extends ConsumerState<SalarySlipsScreen> {
  bool _employeeOpen = true;
  bool _bankOpen = true;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final slips = ref.watch(payslipsProvider);
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? const <String, dynamic>{};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Salary Slips & Payroll', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(onPressed: () => ref.invalidate(payslipsProvider), icon: const Icon(Remix.refresh_line)),
        ],
      ),
      body: slips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _retry(error, () => ref.invalidate(payslipsProvider)),
        data: (items) {
          final latest = items.isEmpty ? null : items.first;
          final history = _showAll ? items : items.take(4).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(payslipsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                if (latest != null) ...[
                  _latestCard(latest),
                  const SizedBox(height: 14),
                  _actions(latest),
                  const SizedBox(height: 14),
                ],
                _employeeCard(profile, latest),
                const SizedBox(height: 14),
                _bankCard(profile, latest),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payslip History', style: AppTypography.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('View and download your monthly salary slips', style: AppTypography.inter(fontSize: 12.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (items.length > 4)
                      GestureDetector(
                        onTap: () => setState(() => _showAll = !_showAll),
                        child: Text(_showAll ? 'Show Less' : 'View All >', style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty) _empty('No salary slips yet') else for (final slip in history) ...[_historyCard(slip), const SizedBox(height: 10)],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _latestCard(Map<String, dynamic> slip) {
    final status = '${slip['status'] ?? 'GENERATED'}'.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F763E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LATEST SALARY SLIP', style: AppTypography.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    const SizedBox(height: 2),
                    Text(_month(slip), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text('[$status]', style: AppTypography.inter(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Net Payable', style: AppTypography.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(AppCurrency.format(_num(slip, const ['netSalary', 'netPay', 'amount'])), style: AppTypography.inter(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Remix.calendar_check_line, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text('Disbursed on: ${_slipDate(slip)}', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _breakBox('Basic', _num(slip, const ['basicSalary', 'basic'])),
              const SizedBox(width: 6),
              _breakBox('Allowances', _num(slip, const ['allowances']) + _num(slip, const ['hra', 'specialAllowance'])),
              const SizedBox(width: 6),
              _breakBox('Reimbursement', _num(slip, const ['reimbursement'])),
              const SizedBox(width: 6),
              _breakBox('Total Deductions', _num(slip, const ['totalDeductions', 'deductions'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakBox(String label, num value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: AppTypography.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, child: Text(AppCurrency.format(value), maxLines: 1, style: AppTypography.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }

  Widget _actions(Map<String, dynamic> slip) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openSlip(slip),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Remix.eye_line, size: 17),
              label: Text('View Salary Slip', style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _download(slip),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Remix.download_2_line, size: 17),
              label: Text('Download PDF', style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _employeeCard(Map profile, Map<String, dynamic>? slip) {
    String pick(List<String> keys, String fallback) {
      for (final key in keys) {
        final value = '${profile[key] ?? slip?[key] ?? ''}'.trim();
        if (value.isNotEmpty && value != 'null') return value;
      }
      return fallback;
    }

    return _foldCard(
      title: 'Employee Information',
      icon: Remix.user_3_line,
      open: _employeeOpen,
      onTap: () => setState(() => _employeeOpen = !_employeeOpen),
      child: Column(
        children: [
          _pair('EMPLOYEE NAME', pick(const ['name'], '—'), 'JOINING DATE', _prettyDate(profile['joiningDate'] ?? slip?['joiningDate'])),
          const SizedBox(height: 12),
          _pair('EMPLOYEE ID', pick(const ['employeeCode', 'code'], '—'), 'EMPLOYMENT TYPE', pick(const ['employmentType'], 'Full-Time')),
          const SizedBox(height: 12),
          _pair('DESIGNATION', pick(const ['designation'], '—'), 'LOCATION', pick(const ['branch', 'office'], 'Head Office')),
          const SizedBox(height: 12),
          _pair('DEPARTMENT', pick(const ['department'], '—'), 'REPORTING MANAGER', pick(const ['manager', 'reportingManager'], 'Direct Reporting')),
        ],
      ),
    );
  }

  Widget _bankCard(Map profile, Map<String, dynamic>? slip) {
    final bank = profile['bankDetails'] is Map ? Map<String, dynamic>.from(profile['bankDetails'] as Map) : slip?['bankDetails'] is Map ? Map<String, dynamic>.from(slip!['bankDetails'] as Map) : const <String, dynamic>{};
    final account = '${bank['accountNumber'] ?? bank['accountNo'] ?? ''}'.trim();
    return _foldCard(
      title: 'Bank & Payment Details',
      icon: Remix.bank_card_line,
      open: _bankOpen,
      onTap: () => setState(() => _bankOpen = !_bankOpen),
      child: Column(
        children: [
          _pair('PAYMENT MODE', '${slip?['paymentMode'] ?? bank['paymentMode'] ?? 'Bank Transfer'}', 'BANK NAME', '${bank['bankName'] ?? bank['bank'] ?? '—'}'),
          const SizedBox(height: 12),
          _pair('ACCOUNT NUMBER', _mask(account), 'IFSC CODE', '${bank['ifscCode'] ?? bank['ifsc'] ?? '—'}'),
          const SizedBox(height: 12),
          _pair('PAYMENT REFERENCE', '${slip?['paymentReference'] ?? slip?['slipNumber'] ?? '—'}', 'DISBURSEMENT DATE', slip == null ? '—' : _slipDate(slip)),
        ],
      ),
    );
  }

  Widget _foldCard({required String title, required IconData icon, required bool open, required VoidCallback onTap, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.lightPrimary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: AppTypography.inter(fontSize: 14.5, fontWeight: FontWeight.w700))),
                  Icon(open ? Remix.arrow_up_s_line : Remix.arrow_down_s_line, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (open) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> slip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.lightPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Remix.file_list_3_line, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_month(slip), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Disbursed on ${_slipDate(slip)}', style: AppTypography.inter(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppCurrency.format(_num(slip, const ['netSalary', 'netPay', 'amount'])), style: AppTypography.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.darkPrimary)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _openSlip(slip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(color: AppColors.lightPrimary, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Remix.eye_line, size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text('View', style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Remix.more_2_line, size: 16, color: AppColors.textSecondary),
                    onSelected: (value) {
                      if (value == 'view') _openSlip(slip);
                      if (value == 'download') _download(slip);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View Breakdown')),
                      PopupMenuItem(value: 'download', child: Text('Download PDF')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSlip(Map<String, dynamic> slip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) => SalarySlipBreakdown(slip: slip, controller: controller),
      ),
    );
  }

  Future<void> _download(Map<String, dynamic> slip) async {
    final id = slip['id'];
    if (id == null || '$id'.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This salary slip has no PDF yet.')));
      return;
    }
    try {
      await ref.read(productionApiProvider).downloadPayslip(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary slip PDF downloaded.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key, required this.slip});
  final Map<String, dynamic> slip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Salary Slip Breakdown', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: SalarySlipBreakdown(slip: slip),
    );
  }
}

class SalarySlipBreakdown extends StatelessWidget {
  const SalarySlipBreakdown({super.key, required this.slip, this.controller});
  final Map<String, dynamic> slip;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final earnings = <(String, num)>[
      ('Basic Salary', _num(slip, const ['basicSalary', 'basic'])),
      ('HRA Allowance', _num(slip, const ['hra'])),
      ('Allowances & Special', _num(slip, const ['allowances']) + _num(slip, const ['specialAllowance'])),
    ];
    final extra = _num(slip, const ['extraWorkingPay', 'overtime']);
    final reimbursement = _num(slip, const ['reimbursement']);
    if (extra > 0) earnings.add(('Extra Working Pay', extra));
    if (reimbursement > 0) earnings.add(('Expense Reimbursement', reimbursement));
    final deductions = <(String, num)>[
      ('Provident Fund (PF)', _num(slip, const ['pf'])),
      ('ESI Contribution', _num(slip, const ['esi'])),
      ('TDS / Income Tax', _num(slip, const ['tds']) + _num(slip, const ['professionalTax'])),
    ];
    final loan = _num(slip, const ['loanDeduction']);
    final lop = _num(slip, const ['unpaidLeaveDeduction', 'lop']);
    if (loan > 0) deductions.add(('Loan Deduction (EMI)', loan));
    if (lop > 0) deductions.add(('Loss of Pay (Unpaid Leave)', lop));
    final rows = earnings.length > deductions.length ? earnings.length : deductions.length;
    final earnTotal = earnings.fold<num>(0, (sum, row) => sum + row.$2);
    final deductTotal = _num(slip, const ['totalDeductions', 'deductions']);
    final net = _num(slip, const ['netSalary', 'netPay', 'amount']);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
        Text('Salary Slip Breakdown', style: AppTypography.inter(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Pay Period: ${_month(slip)}', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F763E))),
        const SizedBox(height: 16),
        Text('SALARY BREAKDOWN', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Expanded(child: _amountLabel('MONTHLY SALARY', _num(slip, const ['grossSalary', 'monthlySalary']))),
              _amountLabel('NET PAYABLE', net, alignEnd: true, valueColor: const Color(0xFF0F763E)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: const BoxConstraints(minWidth: 520),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF0F763E),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    _head('EARNINGS', 155),
                    _head('AMOUNT', 100, align: TextAlign.right),
                    const SizedBox(width: 16),
                    _head('DEDUCTIONS', 165),
                    _head('AMOUNT', 100, align: TextAlign.right),
                  ]),
                ),
                for (var index = 0; index < rows; index++)
                  Container(
                    color: index.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                    child: Row(children: [
                      _cell(index < earnings.length ? earnings[index].$1 : '—', 155, muted: index >= earnings.length),
                      _cell(index < earnings.length ? AppCurrency.format(earnings[index].$2) : '—', 100, align: TextAlign.right, muted: index >= earnings.length),
                      const SizedBox(width: 16),
                      _cell(index < deductions.length ? deductions[index].$1 : '—', 165, muted: index >= deductions.length),
                      _cell(index < deductions.length ? AppCurrency.format(deductions[index].$2) : '—', 100, align: TextAlign.right, color: const Color(0xFFDC2626), muted: index >= deductions.length),
                    ]),
                  ),
                Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(children: [
                    _cell('Total Earnings', 155, bold: true),
                    _cell(AppCurrency.format(earnTotal), 100, align: TextAlign.right, bold: true),
                    const SizedBox(width: 16),
                    _cell('Total Deductions', 165, bold: true),
                    _cell(AppCurrency.format(deductTotal), 100, align: TextAlign.right, bold: true, color: const Color(0xFFDC2626)),
                  ]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFE8F9EE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF86EFAC), width: 1.2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NET PAYABLE (TAKE HOME SALARY)', style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF0F763E))),
              const SizedBox(height: 4),
              Text(AppCurrency.format(net), style: AppTypography.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F763E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountLabel(String label, num value, {bool alignEnd = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(AppCurrency.format(value), style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _head(String text, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(width: width, child: Text(text, textAlign: align, style: AppTypography.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)));
  }

  Widget _cell(String text, double width, {TextAlign align = TextAlign.left, bool bold = false, bool muted = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(text, textAlign: align, style: AppTypography.inter(fontSize: 12.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: muted ? const Color(0xFF94A3B8) : color ?? AppColors.textPrimary)),
    );
  }
}

Widget _pair(String leftLabel, String leftValue, String rightLabel, String rightValue) {
  Widget side(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    ),
  );
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [side(leftLabel, leftValue), const SizedBox(width: 12), side(rightLabel, rightValue)]);
}

num _num(Map slip, List<String> keys) {
  for (final key in keys) {
    final value = num.tryParse('${slip[key]}');
    if (value != null) return value;
  }
  return 0;
}

String _month(Map slip) {
  final text = '${slip['payPeriod'] ?? slip['month'] ?? slip['period'] ?? ''}'.trim();
  return text.isEmpty || text == 'null' ? 'Payslip' : text;
}

String _slipDate(Map slip) => _prettyDate(slip['generatedAt'] ?? slip['date'] ?? slip['paidOn'] ?? slip['disbursedOn']);

String _prettyDate(Object? raw) {
  final parsed = DateTime.tryParse('$raw');
  if (parsed == null) return '—';
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${parsed.day} ${months[parsed.month]} ${parsed.year}';
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
