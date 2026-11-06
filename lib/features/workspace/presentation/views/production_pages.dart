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
    required this.onOpenCalendar,
  });
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenCalendar;

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
          data: (items) =>
              _CalendarPreview(items: items, onViewAll: onOpenCalendar),
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

class _CalendarPreview extends StatefulWidget {
  const _CalendarPreview({required this.items, required this.onViewAll});
  final List<Map<String, dynamic>> items;
  final VoidCallback onViewAll;

  @override
  State<_CalendarPreview> createState() => _CalendarPreviewState();
}

class _CalendarPreviewState extends State<_CalendarPreview> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selected = DateTime(_selected.year, _selected.month, _selected.day);
    final monthItems = widget.items.where((item) {
      final date = workDate(item);
      return date != null &&
          date.year == selected.year &&
          date.month == selected.month;
    }).toList();
    final completed = monthItems
        .where((item) => _status(item) == 'COMPLETED')
        .length;
    final remaining = monthItems.length - completed;
    final dates = List.generate(
      7,
      (index) => selected.subtract(Duration(days: 3 - index)),
    );
    final dayItems = widget.items
        .where((item) => _sameDay(workDate(item), selected))
        .toList();
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'EMPLOYEE CALENDAR',
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            InkWell(
              onTap: widget.onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                  const Icon(
                    Remix.arrow_right_s_line,
                    size: 16,
                    color: AppColors.darkPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_monthName(selected.month)} Work Overview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthItems.isEmpty
                        ? 'No Tasks'
                        : remaining > 0
                        ? '$remaining Remaining'
                        : 'All Completed',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                monthItems.isEmpty
                    ? 'No tasks scheduled this month'
                    : '$completed/${monthItems.length} Tasks Completed',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: monthItems.isEmpty ? 0 : completed / monthItems.length,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _sameDay(date, selected);
              final isToday = _sameDay(date, today);
              final hasWork = widget.items.any(
                (item) => _sameDay(workDate(item), date),
              );
              return InkWell(
                onTap: () => setState(() => _selected = date),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: width < 360 ? 48 : 56,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.darkPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkPrimary
                          : isToday
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _weekday(date.weekday),
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: hasWork
                              ? (isSelected ? Colors.white : AppColors.actionGreen)
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${selected.day} ${_monthName(selected.month).toUpperCase()} ${selected.year}',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_sameDay(selected, today))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        const SizedBox(height: 8),
        if (dayItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: _cardDecoration(),
            child: Text(
              'No activities scheduled for this date.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...dayItems.map((item) => _UpcomingTaskCard(item: item)),
      ],
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
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.darkPrimary : AppColors.textSecondary,
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

String _weekday(int weekday) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][weekday - 1];

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
);

String _status(Map<String, dynamic> item) =>
    field(item, const ['status'], 'PENDING').toUpperCase();
