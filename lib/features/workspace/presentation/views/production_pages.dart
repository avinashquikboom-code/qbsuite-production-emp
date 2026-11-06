import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../providers/production_providers.dart';

class ProductionHomePage extends ConsumerWidget {
  const ProductionHomePage({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenTasks,
  });
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final attendance = ref.watch(attendanceProvider);
    final works = ref.watch(worksProvider);
    final data = profile.asData?.value ?? const <String, dynamic>{};
    final name = field(data, const ['name', 'fullName'], 'Employee');
    final code = field(data, const ['employeeCode', 'code'], '');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const Icon(Remix.building_2_fill, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.title,
                    style: AppTypography.inter(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'EMPLOYEE WORKSPACE',
                    style: AppTypography.inter(
                      fontSize: 10,
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Remix.notification_3_line),
            ),
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Remix.menu_line),
            ),
          ],
        ),
        Text(
          'Good day,',
          style: AppTypography.inter(color: AppColors.textSecondary),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTypography.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (code.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  code,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
        works.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => _ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(worksProvider),
          ),
          data: (items) => _CalendarPreview(items: items, onViewAll: onOpenTasks),
        ),
        const SizedBox(height: 16),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          leading: const Icon(Remix.task_line, color: AppColors.primary),
          title: const Text('Assigned Tasks'),
          subtitle: const Text('Track daily tasks and milestones'),
          trailing: const Icon(Remix.arrow_right_s_line),
          onTap: onOpenTasks,
        ),
      ],
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.status});
  final Map<String, dynamic> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = status['status'] is Map
        ? Map<String, dynamic>.from(status['status'] as Map)
        : status;
    final office = status['assignedOffice'] ?? status['office'];
    final officeName = office is Map
        ? '${office['name'] ?? ''} ${office['city'] ?? ''}'.trim()
        : '';
    final punchedIn = details['isPunchedIn'] == true ||
        (details['punchInTime']?.toString().isNotEmpty ?? false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Attendance",
            style: AppTypography.inter(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('Check In', '${details['punchInTime'] ?? '--:--'}'),
              _metric('Check Out', '${details['punchOutTime'] ?? '--:--'}'),
              _metric('Working Hours', '${details['workingHours'] ?? '0h 0m'}'),
              _metric('Break Taken', '${details['breakDuration'] ?? '0h 0m'}'),
            ],
          ),
          if (officeName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              officeName,
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ref.invalidate(attendanceProvider),
              icon: const Icon(Remix.refresh_line, size: 16),
              label: const Text('Refresh'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                final api = ref.read(productionApiProvider);
                try {
                  if (punchedIn) {
                    await api.punchOut();
                  } else {
                    await api.punchIn();
                  }
                  ref.invalidate(attendanceProvider);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              icon: const Icon(Remix.fingerprint_line),
              label: Text(punchedIn ? 'PUNCH OUT' : 'PUNCH IN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => SizedBox(
    width: 72,
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview({required this.items, required this.onViewAll});
  final List<Map<String, dynamic>> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Employee Calendar',
                  style: AppTypography.inter(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View All')),
            ],
          ),
          Text(
            '${items.length} tasks scheduled',
            style: AppTypography.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No activities for the loaded schedule.')
          else
            ...items.take(3).map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(workTitle(item)),
                subtitle: Text(workWhen(item)),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductionWorkPage extends ConsumerWidget {
  const ProductionWorkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = ref.watch(worksProvider);
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? {};
    return works.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(worksProvider),
      ),
      data: (items) {
        final pending = items.where((item) => _status(item) == 'PENDING').length;
        final progress = items
            .where((item) => _status(item).contains('PROGRESS'))
            .length;
        final done = items.where((item) => _status(item) == 'COMPLETED').length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Production Overview',
              style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              field(profile, const ['designation'], 'Production Employee'),
              style: AppTypography.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _count('Total', items.length),
                _count('In Progress', progress),
                _count('Pending', pending),
                _count('Completed', done),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No production tasks are assigned.')
            else
              ...items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(workTitle(item)),
                    subtitle: Text(
                      '${workCustomer(item)}\n${workWhen(item)} • ${_status(item)}',
                    ),
                    isThreeLine: true,
                    trailing: const Text('View'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProductionTaskPage(task: item),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _count(String label, int value) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
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
    final id = widget.task['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(productionApiProvider).updateWork(id, {
        'status': status,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      });
      ref.invalidate(worksProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            workTitle(task),
            style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(workCustomer(task)),
          const SizedBox(height: 8),
          Text('Status: ${_status(task)}'),
          Text('When: ${workWhen(task)}'),
          Text(field(task, const ['description', 'notes', 'instructions'], '')),
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
          FilledButton(
            onPressed: _saving ? null : () => _update('IN_PROGRESS'),
            child: const Text('Start Task'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : () => _update('COMPLETED'),
            child: const Text('Submit Completed Work'),
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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search customer, task, service, location',
              prefixIcon: Icon(Remix.search_line),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month - 1);
              }),
              icon: const Icon(Remix.arrow_left_s_line),
            ),
            Text(
              '${_month.month}/${_month.year}',
              style: AppTypography.inter(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month + 1);
              }),
              icon: const Icon(Remix.arrow_right_s_line),
            ),
          ],
        ),
        Expanded(
          child: works.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(worksProvider),
            ),
            data: (items) {
              final visible = items.where((item) {
                final text = '${workTitle(item)} ${workCustomer(item)} ${workWhen(item)}'
                    .toLowerCase();
                return _query.isEmpty || text.contains(_query);
              }).toList();
              final days = DateTime(_month.year, _month.month + 1, 0).day;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 5 : 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var day = 1; day <= days; day++)
                        InkWell(
                          onTap: () => setState(() {
                            _selected = DateTime(_month.year, _month.month, day);
                          }),
                          child: Center(
                            child: Text(
                              '$day',
                              style: AppTypography.inter(
                                fontWeight:
                                    _selected.day == day &&
                                        _selected.month == _month.month
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color:
                                    _selected.day == day &&
                                        _selected.month == _month.month
                                    ? AppColors.darkPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${visible.length} assigned tasks'),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('No tasks match this search.'),
                    )
                  else
                    ...visible.map(
                      (item) => ListTile(
                        title: Text(workTitle(item)),
                        subtitle: Text(workWhen(item)),
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
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            field(data, const ['name', 'fullName'], 'Employee'),
            style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(field(data, const ['designation'], '')),
          Text(field(data, const ['employeeCode', 'code'], '')),
          Text(field(data, const ['department'], '')),
          Text(field(data, const ['branch', 'email'], '')),
          Text(field(data, const ['email'], '')),
          const SizedBox(height: 16),
          const ListTile(title: Text('Edit Profile')),
          ListTile(
            title: const Text('My Attendance Logs'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AttendanceLogPage()),
            ),
          ),
          const ListTile(title: Text('Leave & Remote Applications')),
          const ListTile(title: Text('Salary Slips & Payslips')),
          const ListTile(title: Text('Account Settings')),
          const SizedBox(height: 8),
          Text('Recent Payslips', style: AppTypography.inter(fontWeight: FontWeight.w700)),
          slips.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(payslipsProvider),
            ),
            data: (items) => items.isEmpty
                ? const Text('No payslips returned for this account.')
                : Column(
                    children: [
                      for (final slip in items.take(6))
                        ListTile(
                          title: Text(field(slip, const ['month', 'period'], 'Payslip')),
                          subtitle: Text(
                            AppCurrency.format(
                              num.tryParse('${slip['netSalary'] ?? slip['amount'] ?? 0}') ??
                                  0,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
            child: const Text('Sign Out Account'),
          ),
          const SizedBox(height: 8),
          Text(
            AppConfig.title,
            textAlign: TextAlign.center,
            style: AppTypography.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
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
      appBar: AppBar(title: const Text('Attendance Log')),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    }),
                    icon: const Icon(Remix.arrow_left_s_line),
                  ),
                  Expanded(
                    child: Text(
                      '${_month.month}/${_month.year}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    }),
                    icon: const Icon(Remix.arrow_right_s_line),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _month = DateTime(DateTime.now().year, DateTime.now().month);
                      _filter = 'All';
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in ['All', 'Present', 'Late', 'Half Day', 'Absent'])
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == label,
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                ],
              ),
              Text('${filtered.length} records'),
              for (final item in filtered)
                ListTile(
                  title: Text('${item['date'] ?? item['day'] ?? ''}'),
                  subtitle: Text(
                    '${item['status'] ?? ''} • In ${item['checkIn'] ?? item['punchInTime'] ?? '--'} • Out ${item['checkOut'] ?? item['punchOutTime'] ?? '--'}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
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
    field(item, const ['date', 'scheduledDate', 'deadline'], '');

String _status(Map<String, dynamic> item) =>
    field(item, const ['status'], 'PENDING').toUpperCase();
