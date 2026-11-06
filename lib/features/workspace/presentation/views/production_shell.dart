import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../providers/production_providers.dart';
import 'production_pages.dart';
import 'request_overtime_sheet.dart';

class ProductionShell extends ConsumerStatefulWidget {
  const ProductionShell({super.key});

  @override
  ConsumerState<ProductionShell> createState() => _ProductionShellState();
}

class _ProductionShellState extends ConsumerState<ProductionShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  String _drawerItem = 'Dashboard';

  void _selectTab(int index) {
    setState(() {
      _index = index;
      _drawerItem = switch (index) {
        1 => 'My Work',
        2 => 'Calendar',
        3 => 'Profile',
        _ => 'Dashboard',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductionHomePage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenTasks: () {},
      ),
      const ProductionWorkPage(),
      const ProductionCalendarPage(),
      const ProductionProfilePage(),
    ];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _ProductionDrawer(
        selected: _drawerItem,
        onSelect: (label) {
          Navigator.pop(context);
          switch (label) {
            case 'Dashboard':
              _selectTab(0);
            case 'Attendance':
              setState(() => _drawerItem = label);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AttendanceLogPage(),
                ),
              );
            case 'Request Overtime':
              setState(() => _drawerItem = label);
              showRequestOvertimeSheet(context);
            case 'Settings':
              setState(() => _drawerItem = label);
              _selectTab(3);
            default:
              setState(() => _drawerItem = label);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _PlaceholderPage(title: label),
                ),
              );
          }
        },
      ),
      body: SafeArea(bottom: false, child: pages[_index]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _tab(0, 'Home', Remix.home_5_line, Remix.home_5_fill),
                _tab(1, 'My Work', Remix.movie_line, Remix.movie_fill),
                _tab(2, 'Calendar', Remix.calendar_line, Remix.calendar_fill),
                _tab(3, 'Profile', Remix.user_3_line, Remix.user_3_fill),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, String label, IconData icon, IconData active) {
    final selected = _index == index;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.lightPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected ? active : icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionDrawer extends ConsumerWidget {
  const _ProductionDrawer({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider).asData?.value ?? {};
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 360 ? width * 0.9 : 320,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Remix.flashlight_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QB Suite',
                        style: AppTypography.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'BUSINESS SUITE',
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.darkPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _initials(_text(profile, const ['name'], 'SP')),
                        style: AppTypography.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(profile, const [
                              'name',
                              'fullName',
                            ], 'Employee'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${_text(profile, const ['employeeCode', 'code'], 'EMP-011')} • ${_text(profile, const ['designation'], 'Production')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _tile('Dashboard', Remix.home_5_line),
                  _section('HRM & WORKPLACE'),
                  _tile('Attendance', Remix.fingerprint_line),
                  _tile('Request Overtime', Remix.time_line),
                  _tile('Requests & Leaves', Remix.calendar_event_line),
                  _tile('Expenses & Claims', Remix.money_dollar_circle_line),
                  _tile('Remote Work', Remix.home_5_line),
                  _tile('Salary Slips', Remix.file_list_3_line),
                  _section('SYSTEM'),
                  _tile('Settings', Remix.settings_3_line),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authViewModelProvider.notifier).signOut();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Remix.logout_box_r_line,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logout',
                          style: AppTypography.inter(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      const Icon(
                        Remix.arrow_right_s_line,
                        color: Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      label,
      style: AppTypography.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _tile(String label, IconData icon) {
    final active = selected == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.lightPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onSelect(label),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? AppColors.darkPrimary
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.inter(
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.darkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Remix.arrow_right_s_line,
                  size: 18,
                  color: active
                      ? AppColors.darkPrimary
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title uses the existing employee record. This screen opens when that module is assigned to your account.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final letters = parts.map((part) => part[0]).take(2).join();
  return letters.isEmpty ? 'SP' : letters.toUpperCase();
}

String _text(Map<String, dynamic> json, List<String> keys, String fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      final nested = value['name']?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}
