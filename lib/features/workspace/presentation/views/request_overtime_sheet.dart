import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/production_api.dart';

Future<void> showRequestOvertimeSheet(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  if (height < 700) {
    return Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const RequestOvertimeSheet(fullScreen: true)));
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const RequestOvertimeSheet(),
  );
}

class RequestOvertimeSheet extends ConsumerStatefulWidget {
  const RequestOvertimeSheet({super.key, this.fullScreen = false});
  final bool fullScreen;

  @override
  ConsumerState<RequestOvertimeSheet> createState() => _RequestOvertimeSheetState();
}

class _RequestOvertimeSheetState extends ConsumerState<RequestOvertimeSheet> {
  final _reason = TextEditingController();
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _type = 'BEFORE_SHIFT';
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _attendance = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(productionApiProvider);
    try {
      final results = await Future.wait([api.profile(), api.attendanceToday()]);
      if (!mounted) return;
      setState(() {
        _profile = results[0];
        _attendance = results[1];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _reason.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String _clock(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _ampm(TimeOfDay time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  int get _minutes {
    final start = _start.hour * 60 + _start.minute;
    var end = _end.hour * 60 + _end.minute;
    if (end <= start) end += 1440;
    return end - start;
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      _notice('Enter a reason for overtime.');
      return;
    }
    setState(() => _saving = true);
    try {
      final shift = _attendance['assignedShift'] is Map ? Map<String, dynamic>.from(_attendance['assignedShift'] as Map) : <String, dynamic>{};
      final shiftId = int.tryParse('${shift['id']}');
      await ref.read(productionApiProvider).applyOvertime({
        'overtimeDate': '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        'overtimeType': _type,
        'startTime': _clock(_start),
        'endTime': _clock(_end),
        'reason': _reason.text.trim(),
        if (shiftId != null && shiftId > 0) 'shiftId': shiftId,
        if (_remarks.text.trim().isNotEmpty) 'employeeNotes': _remarks.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      _notice('Overtime application submitted.');
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _notice(error is AppFailure ? error.message : 'The overtime request could not be submitted.');
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final shift = _attendance['assignedShift'] is Map ? Map<String, dynamic>.from(_attendance['assignedShift'] as Map) : <String, dynamic>{};
    final name = '${_profile['firstName'] ?? ''} ${_profile['lastName'] ?? ''}'.trim();
    final employeeName = name.isEmpty ? (_profile['name']?.toString() ?? 'Employee') : name;
    final code = _profile['employeeCode']?.toString() ?? '—';
    final shiftLabel = shift.isEmpty ? 'Not assigned' : '${shift['startTime'] ?? ''} – ${shift['endTime'] ?? ''}';
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final body = Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
        Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Remix.calendar_check_line, color: AppColors.actionGreen),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Apply for Overtime', style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Request overtime for your scheduled shift.', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Remix.close_line)),
        ]),
        const SizedBox(height: 12),
        Text(employeeName, style: AppTypography.inter(fontWeight: FontWeight.w700)),
        Text('Employee ID: $code', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
        Text('Assigned shift: $shiftLabel', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Overtime date'),
          subtitle: Text('${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}'),
          onTap: () async {
            final earliest = DateTime.now().add(const Duration(days: 1));
            final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(earliest.year, earliest.month, earliest.day), lastDate: DateTime.now().add(const Duration(days: 90)));
            if (picked != null) setState(() => _date = picked);
          },
        ),
        Row(children: [
          Expanded(child: _typeCard('BEFORE_SHIFT', 'Before Shift')),
          const SizedBox(width: 10),
          Expanded(child: _typeCard('AFTER_SHIFT', 'After Shift')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _timeButton('Start Time', _start, true)),
          const SizedBox(width: 10),
          Expanded(child: _timeButton('End Time', _end, false)),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.lightPrimary, borderRadius: BorderRadius.circular(14)),
          child: Text('Requested Duration: ${_minutes ~/ 60}h ${_minutes % 60}m', style: AppTypography.inter(fontWeight: FontWeight.w800, color: AppColors.darkPrimary)),
        ),
        TextField(controller: _reason, maxLength: 250, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Reason for Overtime', hintText: 'Enter reason for overtime...')),
        TextField(controller: _remarks, maxLength: 250, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Optional Remarks', hintText: 'Add any additional remarks...')),
      ])),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: AppColors.actionGreen),
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Remix.send_plane_2_line),
            label: Text(_saving ? 'Submitting...' : 'Submit Application'),
          ),
        ),
      ),
    ]);
    if (widget.fullScreen) return Scaffold(backgroundColor: Colors.white, body: SafeArea(child: body));
    return SizedBox(height: MediaQuery.sizeOf(context).height * 0.92, child: body);
  }

  Widget _typeCard(String value, String title) {
    final selected = _type == value;
    return InkWell(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.actionGreen : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(child: Text(title, style: AppTypography.inter(fontWeight: FontWeight.w700))),
          if (selected) const Icon(Remix.checkbox_circle_fill, color: AppColors.actionGreen, size: 18),
        ]),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay time, bool start) => OutlinedButton(
    onPressed: () async {
      final picked = await showTimePicker(context: context, initialTime: time);
      if (picked != null) setState(() => start ? _start = picked : _end = picked);
    },
    child: Column(children: [
      Text(label, style: AppTypography.inter(fontSize: 11, color: AppColors.textSecondary)),
      Text(_ampm(time), style: AppTypography.inter(fontWeight: FontWeight.w700)),
    ]),
  );
}
