import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../notifications/presentation/views/notifications_view.dart';
import '../../data/production_api.dart';
import '../providers/production_providers.dart';
import 'employee_screens.dart';
import 'request_overtime_sheet.dart';

bool _otWindowOpen(Map<String, dynamic> row) {
  final date = (row['overtimeDate'] ?? '').toString();
  final day = date.length >= 10 ? date.substring(0, 10) : date;
  final start = DateTime.tryParse('${day}T${row['startTime']}:00');
  final end = DateTime.tryParse('${day}T${row['endTime']}:00');
  if (start == null || end == null) return false;
  final finish = end.isAfter(start) ? end : end.add(const Duration(days: 1));
  final now = DateTime.now();
  return !now.isBefore(start) && !now.isAfter(finish);
}

bool _canCancelOt(Map<String, dynamic> row) {
  final status = (row['sessionStatus'] ?? row['status'] ?? '').toString().toUpperCase();
  if (status == 'PENDING') return true;
  if (status != 'APPROVED' || row['actualStartAt'] != null) return false;
  final date = (row['overtimeDate'] ?? '').toString();
  final start = DateTime.tryParse('${date.length >= 10 ? date.substring(0, 10) : date}T${row['startTime']}:00');
  return start != null && DateTime.now().isBefore(start);
}

Future<void> _requestOtCancellation(BuildContext context, WidgetRef ref, Map<String, dynamic> row) async {
  final reason = TextEditingController();
  final remarks = TextEditingController();
  final id = int.tryParse('${row['id']}') ?? 0;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Request OT Cancellation', style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Are you sure you want to cancel your approved overtime request?', style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${(row['overtimeDate'] ?? '').toString().split('T').first} · ${row['overtimeType']} · ${row['startTime']} – ${row['endTime']}', style: AppTypography.inter(fontWeight: FontWeight.w700)),
        TextField(controller: reason, maxLength: 250, decoration: const InputDecoration(labelText: 'Reason for cancellation')),
        TextField(controller: remarks, maxLength: 250, decoration: const InputDecoration(labelText: 'Remarks (optional)')),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (reason.text.trim().isEmpty) return; Navigator.pop(sheetContext, true); }, child: const Text('Submit cancellation'))),
      ]),
    ),
  );
  if (saved != true || !context.mounted) return;
  try {
    await ref.read(productionApiProvider).cancelOvertime(id, reason: reason.text.trim(), remarks: remarks.text);
    ref.invalidate(myOvertimeProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation request submitted.')));
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  }
}

class _ProductionOtActions extends StatelessWidget {
  const _ProductionOtActions({required this.rows, required this.onApply, required this.onCancel});
  final List<Map<String, dynamic>> rows;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final row = rows.isEmpty ? null : rows.first;
    final status = row == null ? '' : (row['sessionStatus'] ?? row['status'] ?? '').toString().toUpperCase();
    final canCancel = row != null && _canCancelOt(row);
    final start = row != null && (status == 'APPROVED' || status == 'CANCELLATION_REJECTED') && _otWindowOpen(row);
    if (status == 'IN_PROGRESS' && row != null) {
      return Column(children: [
        _ProductionOtTimer(row: row),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: onApply, child: Text('End OT', style: AppTypography.inter(fontWeight: FontWeight.w700)))),
      ]);
    }
    return Row(children: [
      Expanded(child: SizedBox(height: 48, child: OutlinedButton(
        onPressed: onApply,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(start ? 'Start OT' : 'Apply OT', style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkPrimary)),
      ))),
      const SizedBox(width: 10),
      Expanded(child: SizedBox(height: 48, child: OutlinedButton(
        onPressed: canCancel ? onCancel : null,
        style: OutlinedButton.styleFrom(side: BorderSide(color: canCancel ? const Color(0xFFB91C1C) : const Color(0xFFE2E8F0), width: 1.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text('Cancel OT', style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700, color: canCancel ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8))),
      ))),
    ]);
  }
}

class _ProductionOtTimer extends StatefulWidget {
  const _ProductionOtTimer({required this.row});
  final Map<String, dynamic> row;
  @override
  State<_ProductionOtTimer> createState() => _ProductionOtTimerState();
}

class _ProductionOtTimerState extends State<_ProductionOtTimer> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }
  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse('${widget.row['actualStartAt'] ?? ''}');
    final server = DateTime.tryParse('${widget.row['serverNow'] ?? ''}');
    final offset = start == null || server == null ? Duration.zero : server.difference(DateTime.now());
    final elapsed = start == null ? Duration.zero : DateTime.now().add(offset).difference(start);
    final worked = elapsed.isNegative ? 0 : elapsed.inMinutes;
    final approved = int.tryParse('${widget.row['approvedMinutes'] ?? widget.row['totalMinutes'] ?? 0}') ?? 0;
    String clock(int minutes) { final safe = minutes < 0 ? 0 : minutes; return '${safe ~/ 60}h ${(safe % 60).toString().padLeft(2, '0')}m'; }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBBF7D0))),
      child: Text('OT In Progress · worked ${clock(worked)} · approved ${clock(approved)} · remaining ${clock(approved - worked)}', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF166534))),
    );
  }
}

class ProductionHomePage extends ConsumerWidget {
  const ProductionHomePage({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenTasks,
  });
  final VoidCallback onOpenDrawer;
  // ignore: unused_field
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final attendance = ref.watch(attendanceProvider);
    final data = profile.asData?.value ?? const <String, dynamic>{};
    final name = field(data, const ['name', 'fullName'], 'Employee');
    final code = field(data, const ['employeeCode', 'code'], '');
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.darkPrimary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Remix.building_2_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConfig.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'EMPLOYEE WORKSPACE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.darkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsView(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Remix.notification_3_line,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
                IconButton(
                  tooltip: 'Open Menu',
                  onPressed: onOpenDrawer,
                  icon: const Icon(
                    Remix.menu_line,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (code.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        attendance.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(attendanceProvider),
          ),
          data: (status) => _AttendanceCard(status: status),
        ),
        const SizedBox(height: 16),
        const _EmployeeCalendarSoon(),
        /*
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _softCard(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Remix.checkbox_circle_line,
                  color: AppColors.darkPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Tasks',
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Track daily tasks & milestones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onOpenTasks,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tasks',
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        */
      ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceCard extends ConsumerStatefulWidget {
  const _AttendanceCard({required this.status});
  final Map<String, dynamic> status;

  @override
  ConsumerState<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<_AttendanceCard> {
  bool _busy = false;
  bool _locating = false;
  double? _distanceMeters;

  Map get _office {
    final office = widget.status['assignedOffice'] ?? widget.status['office'];
    return office is Map ? office : const {};
  }

  Map<String, dynamic> get _details {
    final status = widget.status['status'];
    return status is Map ? Map<String, dynamic>.from(status) : widget.status;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshGps());
  }

  Future<void> _refreshGps() async {
    if (_locating || _office.isEmpty) return;
    setState(() => _locating = true);
    try {
      final meters = await ref.read(productionApiProvider).distanceToOffice(_office);
      if (mounted) setState(() => _distanceMeters = meters);
    } catch (_) {
      if (mounted) setState(() => _distanceMeters = null);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(attendanceProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPunchOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                    child: const Icon(Remix.logout_box_r_line, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confirm Punch Out', style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Finalize your attendance for today', style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Are you sure you want to punch out? This will finalize your shift and record your check-out timestamp.',
                style: AppTypography.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheet, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () => Navigator.pop(sheet, true),
                      child: const Text('Yes, Punch Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) await _run(() => ref.read(productionApiProvider).punchOut());
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    final punchedIn = details['isPunchedIn'] == true || _clock(details['punchInTime']) != '--:--';
    final checkedOut = _clock(details['punchOutTime']) != '--:--';
    final onBreak = details['isOnBreak'] == true;
    final remote = widget.status['isRemoteWorkActive'] == true || widget.status['workMode'] == 'REMOTE';
    final working = punchedIn && !onBreak && !checkedOut;
    final officeName = '${_office['name'] ?? 'Head Office'}'.trim();
    final radius = num.tryParse('${_office['radiusMeters']}')?.toDouble();
    final inside = _distanceMeters != null && radius != null && _distanceMeters! <= radius;
    final badge = checkedOut
        ? (bg: const Color(0xFFE2E8F0), text: const Color(0xFF334155), dot: const Color(0xFF64748B), label: 'Completed')
        : onBreak
        ? (bg: const Color(0xFFFEF3C7), text: const Color(0xFF92400E), dot: const Color(0xFFF59E0B), label: 'On Break')
        : working
        ? (bg: const Color(0xFFDCFCE7), text: const Color(0xFF166534), dot: AppColors.primary, label: 'Working')
        : (bg: const Color(0xFFF1F5F9), text: const Color(0xFF64748B), dot: const Color(0xFF94A3B8), label: 'Not Checked In');
    final location = remote
        ? 'Approved Remote Work Mode'
        : _distanceMeters == null
        ? '$officeName • GPS Locating...'
        : '$officeName • ${inside ? 'Inside Office' : 'Outside Radius'} (${_distanceMeters!.round()}m)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Attendance", style: AppTypography.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(DateFormat('EEEE, d MMM yyyy').format(DateTime.now()), style: AppTypography.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: badge.dot, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(badge.label, style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: badge.text)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _metric(Remix.login_circle_line, AppColors.primary, 'Check In', _clock(details['punchInTime'])),
                _divider(),
                _metric(Remix.logout_circle_r_line, const Color(0xFFEF4444), 'Check Out', _clock(details['punchOutTime'])),
                _divider(),
                _metric(Remix.time_line, const Color(0xFF3B82F6), 'Working Hours', _hours(details['workingDuration'] ?? details['workingHours']), highlight: working),
                _divider(),
                _metric(Remix.cup_line, const Color(0xFFF59E0B), 'Break Taken', _hours(details['totalBreakDuration'] ?? details['breakDuration']), highlight: onBreak),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Remix.map_pin_2_line, size: 14, color: remote ? const Color(0xFF8B5CF6) : inside ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: remote ? const Color(0xFF8B5CF6) : inside ? AppColors.darkPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              InkWell(
                onTap: _locating ? null : _refreshGps,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_locating ? Remix.loader_4_line : Remix.refresh_line, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text('Refresh GPS', style: AppTypography.inter(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _actions(checkedOut: checkedOut, onBreak: onBreak, punchedIn: punchedIn),
          const SizedBox(height: 10),
          _ProductionOtActions(
            rows: ref.watch(myOvertimeProvider).asData?.value ?? const [],
            onApply: () async {
              final rows = ref.read(myOvertimeProvider).asData?.value ?? const <Map<String, dynamic>>[];
              final status = rows.isEmpty ? '' : (rows.first['sessionStatus'] ?? rows.first['status'] ?? '').toString().toUpperCase();
              final id = rows.isEmpty ? 0 : int.tryParse('${rows.first['id']}') ?? 0;
              final window = rows.isNotEmpty && _otWindowOpen(rows.first);
              if (status == 'CANCELLATION_REQUESTED') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cancellation request is waiting for admin review.')));
                return;
              }
              if ((status == 'IN_PROGRESS' || ((status == 'APPROVED' || status == 'CANCELLATION_REJECTED') && window)) && id > 0) {
                try {
                  await ref.read(productionApiProvider).markOvertime(id, end: status == 'IN_PROGRESS');
                  ref.invalidate(myOvertimeProvider);
                } catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
                }
                return;
              }
              await showRequestOvertimeSheet(context);
              ref.invalidate(myOvertimeProvider);
            },
            onCancel: () {
              final rows = ref.read(myOvertimeProvider).asData?.value ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty || !_canCancelOt(rows.first)) return;
              _requestOtCancellation(context, ref, rows.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _actions({required bool checkedOut, required bool onBreak, required bool punchedIn}) {
    if (_busy) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.lightPrimary, disabledBackgroundColor: AppColors.lightPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text('Processing...', style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkPrimary)),
        ),
      );
    }
    if (checkedOut) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Remix.checkbox_circle_fill, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Attendance Completed', style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
          ],
        ),
      );
    }
    if (onBreak) {
      return Row(
        children: [
          Expanded(child: _solid(Remix.play_circle_line, 'End Break', AppColors.primary, () => _run(() => ref.read(productionApiProvider).endBreak()))),
          const SizedBox(width: 10),
          Expanded(child: _solid(Remix.logout_box_r_line, 'PUNCH OUT', const Color(0xFF94A3B8), () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please end your break before punching out.')));
          })),
        ],
      );
    }
    if (punchedIn) {
      return Row(
        children: [
          Expanded(child: _outline(Remix.cup_line, 'Start Break', const Color(0xFFF59E0B), () => _run(() => ref.read(productionApiProvider).startBreak()))),
          const SizedBox(width: 10),
          Expanded(child: _solid(Remix.logout_box_r_line, 'PUNCH OUT', const Color(0xFFEF4444), _confirmPunchOut)),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: () => _run(() => ref.read(productionApiProvider).punchIn()),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: const Icon(Remix.fingerprint_line, size: 20),
        label: Text('PUNCH IN', style: AppTypography.inter(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _solid(IconData icon, String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: Icon(icon, size: 18),
        label: Text(label, style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _outline(IconData icon, String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: Icon(icon, size: 18),
        label: Text(label, style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  Widget _metric(IconData icon, Color color, String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: highlight ? AppColors.primary : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  String _clock(Object? value) {
    final parsed = DateTime.tryParse('$value')?.toLocal();
    if (parsed == null) return _displayTime(value);
    return DateFormat('h:mm a').format(parsed);
  }

  String _hours(Object? value) {
    if (value is num) {
      final minutes = (value * 60).round();
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return _displayDuration(value);
  }
}

String _displayTime(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text == 'null' || text == '--' || text == '—') {
    return '--:--';
  }
  return text;
}

String _displayDuration(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text == 'null' || text == '--' || text == '—') {
    return '0h 0m';
  }
  return text;
}

BoxDecoration _softCard() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

class _EmployeeCalendarSoon extends StatelessWidget {
  const _EmployeeCalendarSoon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: _softCard(),
      child: Column(
        children: [
          Text(
            'EMPLOYEE CALENDAR',
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Remix.calendar_line, color: AppColors.darkPrimary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'Coming Soon',
            style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'The work calendar and daily activities are coming soon.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ProductionWorkPage extends ConsumerStatefulWidget {
  const ProductionWorkPage({super.key});

  @override
  ConsumerState<ProductionWorkPage> createState() => _ProductionWorkPageState();
}

class _ProductionWorkPageState extends ConsumerState<ProductionWorkPage> {
  String _filter = 'All Dates';
  DateTime? _pickedDate;

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksProvider);
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? {};
    final designation = field(profile, const ['designation'], '');
    return works.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(worksProvider),
      ),
      data: (items) {
        final visible = items.where((item) => _matchesWorkFilter(item, _filter, custom: _pickedDate)).toList();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        int count(bool Function(Map<String, dynamic>) test) => items.where(test).length;
        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 360;
        final cardWidth = (width * 0.30).clamp(104.0, 128.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 12, compact ? 12 : 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Production Overview',
                    style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w700, height: 1.15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Authorized Modules',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                      if (designation.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              designation.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.darkPrimary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 10, compact ? 12 : 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Remix.dashboard_3_line, size: 15, color: AppColors.darkPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Production Metrics',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${visible.length} filtered items',
                        style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _metricCard(Remix.task_line, const Color(0xFF0284C7), const Color(0xFFE0F2FE), 'Total', items.length, cardWidth),
                        _metricCard(Remix.loader_2_line, const Color(0xFF2563EB), const Color(0xFFDBEAFE), 'In Progress', count((item) => _status(item).contains('PROGRESS')), cardWidth),
                        _metricCard(Remix.time_line, const Color(0xFFD97706), const Color(0xFFFEF3C7), 'Pending', count((item) => _status(item) == 'PENDING'), cardWidth),
                        _metricCard(Remix.checkbox_circle_line, const Color(0xFF16A34A), const Color(0xFFDCFCE7), 'Completed', count((item) => _status(item) == 'COMPLETED'), cardWidth),
                        _metricCard(Remix.error_warning_line, const Color(0xFFDC2626), const Color(0xFFFEE2E2), 'Blocked', count((item) => _status(item).contains('BLOCK') || _status(item).contains('CANCEL')), cardWidth),
                        _metricCard(Remix.calendar_check_line, const Color(0xFF7C3AED), const Color(0xFFEDE9FE), "Today's Work", count((item) => _sameDay(workDate(item) ?? DateTime(2000), today)), cardWidth),
                        _metricCard(Remix.alarm_warning_line, const Color(0xFFEA580C), const Color(0xFFFFEDD5), 'Overdue', count((item) {
                          final date = workDate(item);
                          return date != null && date.isBefore(today) && _status(item) != 'COMPLETED';
                        }), cardWidth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All Dates'),
                    _filterChip('Today'),
                    _filterChip('Tomorrow'),
                    _filterChip('This Week'),
                    _filterChip('Pick Date', icon: Remix.calendar_line),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                              child: const Icon(Remix.file_list_3_line, size: 38, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            Text('No work assigned', textAlign: TextAlign.center, style: AppTypography.inter(fontSize: compact ? 15 : 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              'Your assigned activities will appear here.',
                              textAlign: TextAlign.center,
                              style: AppTypography.inter(fontSize: 13.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 14, compact ? 12 : 16, 24),
                      children: [for (final item in visible) _workCard(item)],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _pickedDate = picked;
      _filter = 'Pick Date';
    });
  }

  Widget _filterChip(String label, {IconData? icon}) {
    final selected = _filter == label;
    final text = label == 'Pick Date' && selected && _pickedDate != null
        ? '${_pickedDate!.day} ${_monthName(_pickedDate!.month).substring(0, 3)} ${_pickedDate!.year}'
        : label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: label == 'Pick Date' ? _pickDate : () => setState(() => _filter = label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: selected ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: AppTypography.inter(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workCard(Map<String, dynamic> item) {
    final status = _status(item);
    final color = status == 'COMPLETED'
        ? AppColors.darkPrimary
        : status.contains('PROGRESS')
        ? const Color(0xFF2563EB)
        : const Color(0xFFD97706);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ProductionTaskPage(task: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        workTitle(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: AppTypography.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  workCustomer(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(workWhen(item), style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, Color color, Color background, String label, int value, double width) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: background),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$value', style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        ],
      ),
    );
  }
}

class ProductionTaskPage extends ConsumerStatefulWidget {
  const ProductionTaskPage({super.key, required this.task});
  final Map<String, dynamic> task;

  @override
  ConsumerState<ProductionTaskPage> createState() => _ProductionTaskPageState();
}

class _ProductionTaskPageState extends ConsumerState<ProductionTaskPage> {
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _update(String status) async {
    setState(() => _saving = true);
    widget.task['status'] = status;
    if (_notes.text.trim().isNotEmpty) {
      widget.task['notes'] = _notes.text.trim();
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      appBar: AppBar(title: Text('Task Details', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          16,
          compact ? 12 : 16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            workTitle(task),
            style: AppTypography.inter(fontSize: compact ? 18 : 22, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(workCustomer(task), style: AppTypography.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Status: ${_status(task)}', style: AppTypography.inter(fontSize: 14)),
          Text('When: ${workWhen(task)}', style: AppTypography.inter(fontSize: 14)),
          const SizedBox(height: 8),
          Text(field(task, const ['description', 'notes', 'instructions'], ''), style: AppTypography.inter(fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : () => _update('IN_PROGRESS'),
              child: Text('Start Task', style: AppTypography.inter(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saving ? null : () => _update('COMPLETED'),
              child: Text('Submit Completed Work', textAlign: TextAlign.center, style: AppTypography.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductionCalendarPage extends ConsumerStatefulWidget {
  const ProductionCalendarPage({super.key});

  @override
  ConsumerState<ProductionCalendarPage> createState() =>
      _ProductionCalendarPageState();
}

class _ProductionCalendarPageState extends ConsumerState<ProductionCalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();
  bool _week = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _shift(int direction) {
    setState(() {
      if (_week) {
        _selected = _selected.add(Duration(days: 7 * direction));
        _month = DateTime(_selected.year, _selected.month);
      } else {
        _month = DateTime(_month.year, _month.month + direction);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksProvider);
    final today = DateTime.now();
    final weekStart = _selected.subtract(Duration(days: _selected.weekday - 1));
    final weekDays = List.generate(
      7,
      (index) => DateTime(weekStart.year, weekStart.month, weekStart.day + index),
    );
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final query = _search.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'My Calendar',
                  style: AppTypography.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh Calendar',
                onPressed: () => ref.invalidate(worksProvider),
                icon: const Icon(Remix.refresh_line),
              ),
            ],
          ),
        ),
        Expanded(
          child: works.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(worksProvider),
            ),
            data: (items) {
              final selectedItems = items.where((item) {
                if (!_sameDay(workDate(item), _selected)) return false;
                if (query.isEmpty) return true;
                final text =
                    '${workTitle(item)} ${workCustomer(item)} ${workWhen(item)} ${_status(item)}'
                        .toLowerCase();
                return text.contains(query);
              }).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
                    decoration: _cardDecoration(),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search customer, task, service, location...',
                        hintStyle: AppTypography.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Remix.search_2_line,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Remix.close_circle_fill,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _shift(-1),
                              icon: const Icon(Remix.arrow_left_s_line),
                            ),
                            Expanded(
                              child: Text(
                                _week
                                    ? '${_monthName(weekDays.first.month).substring(0, 3)} ${weekDays.first.day} – ${_monthName(weekDays.last.month).substring(0, 3)} ${weekDays.last.day}'
                                    : '${_monthName(_month.month)} ${_month.year}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _shift(1),
                              icon: const Icon(Remix.arrow_right_s_line),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _viewPill('Month', !_week, () {
                                    setState(() => _week = false);
                                  }),
                                  _viewPill('Week', _week, () {
                                    setState(() => _week = true);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        Row(
                          children: [
                            for (final day in const [
                              'MON',
                              'TUE',
                              'WED',
                              'THU',
                              'FRI',
                              'SAT',
                              'SUN',
                            ])
                              Expanded(
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _week ? 7 : daysInMonth + leading,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            if (!_week && index < leading) {
                              return const SizedBox.shrink();
                            }
                            final date = _week
                                ? weekDays[index]
                                : DateTime(
                                    _month.year,
                                    _month.month,
                                    index - leading + 1,
                                  );
                            final selected = _sameDay(date, _selected);
                            final isToday = _sameDay(date, today);
                            final hasWork = items.any(
                              (item) => _sameDay(workDate(item), date),
                            );
                            return InkWell(
                              onTap: () => setState(() {
                                _selected = date;
                                _month = DateTime(date.year, date.month);
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected || !isToday
                                        ? Colors.transparent
                                        : AppColors.primary,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: AppTypography.inter(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : isToday
                                            ? AppColors.darkPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: hasWork
                                            ? (selected
                                                  ? Colors.white
                                                  : AppColors.actionGreen)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selected.day} ${_monthName(_selected.month).toUpperCase()} ${_selected.year} · ASSIGNED TASKS (${selectedItems.length})',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_sameDay(_selected, today))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TODAY',
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          Icon(
                            query.isEmpty
                                ? Remix.calendar_check_line
                                : Remix.search_2_line,
                            size: 40,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            query.isEmpty
                                ? 'No assigned work for this date'
                                : 'No matching tasks',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            query.isEmpty
                                ? 'When you are scheduled or assigned work, it will appear here.'
                                : 'Try a different search for this date.',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...selectedItems.map(
                      (item) => _UpcomingTaskCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ProductionTaskPage(task: item),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _viewPill(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.actionGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UpcomingTaskCard extends StatelessWidget {
  const _UpcomingTaskCard({required this.item, this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _status(item);
    final done = status == 'COMPLETED';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Remix.video_line,
                    color: AppColors.darkPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          workCustomer(item),
                          workWhen(item),
                        ].where((part) => part.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.lightPrimary
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: done
                          ? AppColors.darkPrimary
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductionProfilePage extends ConsumerWidget {
  const ProductionProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final slips = ref.watch(payslipsProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(employeeProfileProvider),
      ),
      data: (data) {
        final name = field(data, const ['name', 'fullName'], 'Employee');
        final designation = field(data, const ['designation'], '');
        final code = field(data, const ['employeeCode', 'code'], '');
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: _softCard(),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Remix.edit_line, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _profileInitials(name),
                      style: AppTypography.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          designation.toUpperCase(),
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          code,
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _profileRow(Remix.briefcase_line, 'Designation:', designation.toUpperCase()),
                  _profileRow(Remix.building_line, 'Department:', field(data, const ['department'], '—').toUpperCase()),
                  _profileRow(Remix.id_card_line, 'Employee Code:', code),
                  _profileRow(Remix.map_pin_line, 'Assigned Branch:', field(data, const ['branch'], '')),
                  _profileRow(Remix.mail_line, 'Email:', field(data, const ['email'], '')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _profileAction(Remix.edit_line, 'Edit Profile', () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
            }),
            _profileAction(Remix.fingerprint_line, 'My Attendance Logs', () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AttendanceLogPage()));
            }),
            _profileAction(Remix.calendar_event_line, 'Leave Applications', () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LeaveApplicationsScreen()));
            }),
            _profileAction(Remix.file_list_3_line, 'Salary Slips & Payslips', () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SalarySlipsScreen()));
            }),
            _profileAction(Remix.settings_3_line, 'Account Settings', () {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountSettingsScreen()));
            }),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: slips.when(
                  loading: () => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Payslips'),
                      SizedBox(height: 12),
                      LinearProgressIndicator(),
                    ],
                  ),
                  error: (error, _) => _payslipError(ref),
                  data: (items) {
                    final recent = items.take(2).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent Payslips',
                                style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (items.isNotEmpty)
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SalarySlipsScreen())),
                                child: Text('View All', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (recent.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Remix.receipt_line, size: 32, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                Text('No payslips available yet.', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Your generated payslips will appear here.', style: AppTypography.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          )
                        else
                          for (var index = 0; index < recent.length; index++) ...[
                            if (index > 0) const Divider(height: 1),
                            _recentPayslipTile(context, recent[index]),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Remix.logout_box_r_line),
              label: Text(
                'Sign Out Account',
                style: AppTypography.inter(fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'QB Suite Production v1.0.0',
              textAlign: TextAlign.center,
              style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              AppConfig.title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
            fontSize: 1,
            height: 1,
            color: Colors.transparent,
          ),
            ),
          ],
        );
      },
    );
  }
}

class AttendanceLogPage extends ConsumerStatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  ConsumerState<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends ConsumerState<AttendanceLogPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final query = (month: _month.month, year: _month.year);
    final history = ref.watch(attendanceHistoryProvider(query));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Attendance Log', style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 18))),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(attendanceHistoryProvider(query)),
        ),
        data: (items) {
          final filtered = items.where((item) {
            final status = '${item['status'] ?? ''}'.toUpperCase();
            return _filter == 'All' || status.contains(_filter.toUpperCase());
          }).toList();
          final present = items.where((item) => '${item['status']}'.toUpperCase() == 'PRESENT').length;
          final late = items.where((item) => '${item['status']}'.toUpperCase().contains('LATE')).length;
          final half = items.where((item) => '${item['status']}'.toUpperCase().contains('HALF')).length;
          final absent = items.where((item) => '${item['status']}'.toUpperCase().contains('ABSENT')).length;
          final now = DateTime.now();
          final years = [now.year - 2, now.year - 1, now.year, now.year + 1];
          if (!years.contains(_month.year)) years.add(_month.year);
          final months = List.generate(12, (index) => _monthName(index + 1));
          final workingDays = items.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(child: _summaryCard('Total Working Days', '$workingDays', Remix.calendar_check_line, const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryCard('Present', '$present', Remix.checkbox_circle_line, AppColors.primary, AppColors.lightPrimary)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _summaryCard('Late', '$late', Remix.time_line, const Color(0xFFF59E0B), const Color(0xFFFEF3C7))),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryCard('Half Day', '$half', Remix.contrast_2_line, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF))),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryCard('Absent', '$absent', Remix.close_circle_line, AppColors.danger, const Color(0xFFFEE2E2))),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _softCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: _monthYearMenu(months, _month.month, (value) => setState(() => _month = DateTime(_month.year, value)))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _monthYearMenu(years.map((year) => '$year').toList(), years.indexOf(_month.year) + 1, (value) => setState(() => _month = DateTime(years[value - 1], _month.month)))),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() {
                            _month = DateTime(now.year, now.month);
                            _filter = 'All';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              children: [
                                const Icon(Remix.refresh_line, size: 14, color: AppColors.darkPrimary),
                                const SizedBox(width: 4),
                                Text('Reset', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _logChip('All', items.length, AppColors.actionGreen),
                          _logChip('Present', present, AppColors.darkPrimary),
                          _logChip('Late', late, const Color(0xFFF59E0B)),
                          _logChip('Half Day', half, const Color(0xFF8B5CF6)),
                          _logChip('Absent', absent, AppColors.danger),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attendance Records',
                      style: AppTypography.inter(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${filtered.length} Records',
                    style: AppTypography.inter(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in filtered) _attendanceRecord(item),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              Text('Days', style: AppTypography.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthYearMenu(List<String> labels, int selected, ValueChanged<int> onChanged) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Remix.arrow_down_s_line, size: 16, color: AppColors.textSecondary),
          style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          items: [
            for (var index = 0; index < labels.length; index++)
              DropdownMenuItem(value: index + 1, child: Text(labels[index], overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _logChip(String label, int count, Color color) {
    final selected = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filter = label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.actionGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.actionGreen : AppColors.border),
          ),
          child: Text(
            '$label $count',
            style: AppTypography.inter(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceRecord(Map<String, dynamic> item) {
    final status = '${item['status'] ?? ''}'.toUpperCase();
    final parsed = DateTime.tryParse('${item['date'] ?? ''}');
    final dateLabel = parsed == null
        ? '${item['date'] ?? ''}'
        : '${parsed.day.toString().padLeft(2, '0')} ${_monthName(parsed.month).substring(0, 3)} ${parsed.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Remix.calendar_line, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(dateLabel, style: AppTypography.inter(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item['day'] ?? ''}',
                  style: AppTypography.inter(color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.contains('HALF') ? const Color(0xFFF3E8FF) : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: status.contains('HALF') ? const Color(0xFF7C3AED) : AppColors.darkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _timeCol('CHECK IN', '${item['checkIn'] ?? '--'}'),
              _timeCol('CHECK OUT', '${item['checkOut'] ?? '--'}'),
              _timeCol('WORK HOURS', '${item['workHours'] ?? '--'}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Remix.map_pin_line, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item['branch'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Text(
                'Break: ${item['breakDuration'] ?? '0h 0m'}',
                style: AppTypography.inter(fontSize: 12, color: const Color(0xFFF59E0B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeCol(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.inter(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

Widget _profileAction(IconData icon, String label, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.darkPrimary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTypography.inter(fontWeight: FontWeight.w700)),
              ),
              const Icon(Remix.arrow_right_s_line, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _profileRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.inter(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _profileInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final letters = parts.map((part) => part[0]).take(2).join();
  return letters.isEmpty ? 'E' : letters.toUpperCase();
}

Widget _recentPayslipTile(BuildContext context, Map<String, dynamic> slip) {
  final net = num.tryParse('${slip['netSalary'] ?? slip['netPay'] ?? slip['amount'] ?? 0}') ?? 0;
  final month = field(slip, const ['month', 'period'], 'Payslip');
  final paid = _paidOn(slip['paidOn'] ?? slip['disbursedOn'] ?? slip['date'] ?? slip['createdAt']);
  void open() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PayslipScreen(slip: slip)));
  return ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: open,
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.lightPrimary, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Remix.receipt_line, color: AppColors.primary, size: 20),
    ),
    title: Text(month, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 14)),
    subtitle: Text(
      '₹ ${net.toStringAsFixed(0)} Net • Paid on $paid',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.inter(color: AppColors.textSecondary, fontSize: 12),
    ),
    trailing: IconButton(
      icon: const Icon(Remix.download_2_line, color: AppColors.primary, size: 20),
      onPressed: open,
    ),
  );
}

String _paidOn(Object? raw) {
  final parsed = DateTime.tryParse('$raw');
  if (parsed == null) return 'Recent';
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month]}';
}

Widget _payslipError(WidgetRef ref) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent Payslips', style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Remix.error_warning_line, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unable to load payslips',
              style: AppTypography.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(payslipsProvider),
            child: Text(
              'Retry',
              style: AppTypography.inter(
                fontWeight: FontWeight.w800,
                color: AppColors.darkPrimary,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String field(Map<String, dynamic> json, List<String> keys, String fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      final nested = value['name']?.toString();
      if (nested != null && nested.trim().isNotEmpty) return nested;
    }
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

String workTitle(Map<String, dynamic> item) =>
    field(item, const ['title', 'name', 'task', 'workType'], 'Production task');

String workCustomer(Map<String, dynamic> item) =>
    field(item, const ['customerName', 'customer', 'project'], '');

String workWhen(Map<String, dynamic> item) =>
    field(item, const ['date', 'scheduledDate', 'deadline', 'startTime'], '');

DateTime? workDate(Map<String, dynamic> item) {
  for (final key in const [
    'scheduledDate',
    'date',
    'deadline',
    'startDate',
    'assignedDate',
  ]) {
    final parsed = DateTime.tryParse('${item[key] ?? ''}');
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  }
  return null;
}

bool _sameDay(DateTime? left, DateTime right) =>
    left != null &&
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[(month - 1).clamp(0, 11)];
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
);

String _status(Map<String, dynamic> item) =>
    field(item, const ['status'], 'PENDING').toUpperCase();

bool _matchesWorkFilter(Map<String, dynamic> item, String filter, {DateTime? custom}) {
  if (filter == 'All' || filter == 'All Dates') return true;
  final date = workDate(item);
  if (date == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (filter == 'Pick Date') return custom != null && _sameDay(date, custom);
  if (filter == 'Today') return _sameDay(date, today);
  if (filter == 'Tomorrow') {
    return _sameDay(date, today.add(const Duration(days: 1)));
  }
  final start = today.subtract(Duration(days: today.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return !date.isBefore(start) && !date.isAfter(end);
}
