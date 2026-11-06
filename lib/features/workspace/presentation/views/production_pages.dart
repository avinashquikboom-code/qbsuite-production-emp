import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          AppConfig.title,
          style: AppTypography.inter(
            fontSize: 1,
            height: 1,
            color: Colors.transparent,
          ),
        ),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
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
                children: [
                  Text(
                    'QB Suite',
                    style: AppTypography.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'EMPLOYEE WORKSPACE',
                    style: AppTypography.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Remix.notification_3_line, color: AppColors.textPrimary),
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Remix.menu_line, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTypography.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (code.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
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
        _displayTime(details['punchInTime']) != '--:--';
    final checkedOut = _displayTime(details['punchOutTime']) != '--:--';
    final statusLabel = checkedOut
        ? 'Completed'
        : punchedIn
        ? 'Working'
        : 'Not Checked In';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCard(),
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
                    Text(
                      "Today's Attendance",
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _metric(
                  Remix.checkbox_circle_line,
                  AppColors.primary,
                  'Check In',
                  _displayTime(details['punchInTime']),
                ),
                _metric(
                  Remix.close_circle_line,
                  const Color(0xFFEF4444),
                  'Check Out',
                  _displayTime(details['punchOutTime']),
                ),
                _metric(
                  Remix.time_line,
                  const Color(0xFF38BDF8),
                  'Working Hours',
                  _displayDuration(details['workingHours']),
                ),
                _metric(
                  Remix.cup_line,
                  const Color(0xFFF59E0B),
                  'Break Taken',
                  _displayDuration(details['breakDuration']),
                ),
              ],
            ),
          ),
          if (officeName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Icon(
                  Remix.map_pin_2_line,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                Text(
                  officeName,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(attendanceProvider),
                  icon: const Icon(Remix.refresh_line, size: 16),
                  label: const Text('Refresh GPS'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ref.read(uiPunchedInProvider.notifier).toggle();
              },
              icon: const Icon(Remix.fingerprint_line),
              label: Text(punchedIn ? 'PUNCH OUT' : 'PUNCH IN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, Color color, String label, String value) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
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
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.border),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

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
          height: 78 * MediaQuery.textScalerOf(context).scale(1),
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

class ProductionWorkPage extends ConsumerStatefulWidget {
  const ProductionWorkPage({super.key});

  @override
  ConsumerState<ProductionWorkPage> createState() => _ProductionWorkPageState();
}

class _ProductionWorkPageState extends ConsumerState<ProductionWorkPage> {
  String _filter = 'Today';

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksProvider);
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? {};
    final designation = field(profile, const ['designation'], 'Senior Photographer');
    return works.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorCard(
        message: error.toString(),
        onRetry: () => ref.invalidate(worksProvider),
      ),
      data: (items) {
        final visible = items.where((item) => _matchesWorkFilter(item, _filter)).toList();
        final pending = visible.where((item) => _status(item) == 'PENDING').length;
        final progress = visible
            .where((item) => _status(item).contains('PROGRESS'))
            .length;
        final done = visible.where((item) => _status(item) == 'COMPLETED').length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Production Overview',
              style: AppTypography.inter(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Supervisory Access',
                  style: AppTypography.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Remix.pie_chart_line, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Production Metrics',
                    style: AppTypography.inter(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${visible.length} filtered items',
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _metricCard(Remix.checkbox_line, const Color(0xFF2563EB), 'Total', visible.length),
                  _metricCard(Remix.sparkling_line, const Color(0xFF2563EB), 'In Progress', progress),
                  _metricCard(Remix.time_line, const Color(0xFFF59E0B), 'Pending', pending),
                  _metricCard(Remix.checkbox_circle_line, AppColors.darkPrimary, 'Completed', done),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in ['Today', 'Tomorrow', 'This Week', 'Pick Date', 'All']) ...[
                    _filterChip(label),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Remix.file_list_3_line,
                        color: Color(0xFF94A3B8),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No production tasks found',
                      style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No production work matches the selected filters for your workspace.',
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...visible.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(workTitle(item)),
                    subtitle: Text('${workCustomer(item)} • ${_status(item)}'),
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

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.actionGreen : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _metricCard(IconData icon, Color color, String label, int value) {
    return Container(
      width: 116,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$value',
            style: AppTypography.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
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
        final name = field(data, const ['name', 'fullName'], 'Sumit Parmar');
        final designation = field(data, const ['designation'], 'Senior Photographer');
        final code = field(data, const ['employeeCode', 'code'], 'EMP-011');
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
                    style: AppTypography.inter(fontSize: 22, fontWeight: FontWeight.w800),
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
                  _profileRow(Remix.building_line, 'Department:', field(data, const ['department'], 'PRODUCTION').toUpperCase()),
                  _profileRow(Remix.id_card_line, 'Employee Code:', code),
                  _profileRow(Remix.map_pin_line, 'Assigned Branch:', field(data, const ['branch'], '')),
                  _profileRow(Remix.mail_line, 'Email:', field(data, const ['email'], '')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _profileAction(Remix.edit_line, 'Edit Profile', () {}),
            _profileAction(Remix.fingerprint_line, 'My Attendance Logs', () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const AttendanceLogPage()),
              );
            }),
            _profileAction(Remix.calendar_event_line, 'Leave & Remote Applications', () {}),
            _profileAction(Remix.file_list_3_line, 'Salary Slips & Payslips', () {}),
            _profileAction(Remix.settings_3_line, 'Account Settings', () {}),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _softCard(),
              child: slips.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => _payslipError(ref),
                data: (items) => items.isEmpty
                    ? _payslipError(ref)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Payslips',
                            style: AppTypography.inter(fontWeight: FontWeight.w800),
                          ),
                          for (final slip in items.take(4))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(field(slip, const ['month', 'period'], 'Payslip')),
                              trailing: Text(
                                AppCurrency.format(
                                  num.tryParse('${slip['netSalary'] ?? slip['amount'] ?? 0}') ?? 0,
                                ),
                              ),
                            ),
                        ],
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
              'QB Suite Employee Mobile v1.0.0',
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
          final present = items.where((item) => '${item['status']}'.toUpperCase() == 'PRESENT').length;
          final late = items.where((item) => '${item['status']}'.toUpperCase().contains('LATE')).length;
          final half = items.where((item) => '${item['status']}'.toUpperCase().contains('HALF')).length;
          final absent = items.where((item) => '${item['status']}'.toUpperCase().contains('ABSENT')).length;
          final demo = _month.year == 2026 && _month.month == 11;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _summaryCard('Total Working Days', '${demo ? 25 : items.length} Days', Remix.calendar_line, const Color(0xFF64748B)),
                  _summaryCard('Present', '${demo ? 1 : present} Days', Remix.checkbox_circle_line, AppColors.darkPrimary),
                  _summaryCard('Late', '${demo ? 0 : late} Days', Remix.time_line, const Color(0xFFF59E0B)),
                  _summaryCard('Half Day', '${demo ? 2 : half} Days', Remix.contrast_2_line, const Color(0xFF8B5CF6)),
                  _summaryCard('Absent', '${demo ? 0 : absent} Days', Remix.close_circle_line, const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: _softCard(),
                child: Row(
                  children: [
                    Expanded(child: Text(_monthName(_month.month), textAlign: TextAlign.center)),
                    Expanded(child: Text('${_month.year}', textAlign: TextAlign.center)),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _month = DateTime(2026, 11);
                        _filter = 'All';
                      }),
                      icon: const Icon(Remix.refresh_line, size: 16),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _logChip('All', items.length, AppColors.actionGreen),
                    _logChip('Present', present, AppColors.darkPrimary),
                    _logChip('Late', late, const Color(0xFFF59E0B)),
                    _logChip('Half Day', half, const Color(0xFF8B5CF6)),
                    _logChip('Absent', absent, const Color(0xFFEF4444)),
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

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: (width - 42) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _softCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.inter(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
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
  return letters.isEmpty ? 'SP' : letters.toUpperCase();
}

Widget _payslipError(WidgetRef ref) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent Payslips', style: AppTypography.inter(fontWeight: FontWeight.w800)),
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

String _weekday(int weekday) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][weekday - 1];

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
);

String _status(Map<String, dynamic> item) =>
    field(item, const ['status'], 'PENDING').toUpperCase();

bool _matchesWorkFilter(Map<String, dynamic> item, String filter) {
  if (filter == 'All' || filter == 'Pick Date') return true;
  final date = workDate(item);
  if (date == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (filter == 'Today') return _sameDay(date, today);
  if (filter == 'Tomorrow') {
    return _sameDay(date, today.add(const Duration(days: 1)));
  }
  final start = today.subtract(Duration(days: today.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return !date.isBefore(start) && !date.isAfter(end);
}
