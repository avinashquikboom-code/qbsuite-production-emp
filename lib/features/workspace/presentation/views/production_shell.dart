import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../providers/production_providers.dart';
import 'production_pages.dart';

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
        onOpenTasks: () => _selectTab(1),
        onOpenCalendar: () => _selectTab(2),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightPrimary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Remix.home_5_line),
            selectedIcon: Icon(Remix.home_5_fill, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Remix.movie_line),
            selectedIcon: Icon(Remix.movie_fill, color: AppColors.primary),
            label: 'My Work',
          ),
          NavigationDestination(
            icon: Icon(Remix.calendar_line),
            selectedIcon: Icon(Remix.calendar_fill, color: AppColors.primary),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Remix.user_3_line),
            selectedIcon: Icon(Remix.user_3_fill, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
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
      width: width < 360 ? width * 0.88 : 300,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QB Suite',
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Business Suite',
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _text(profile, const ['name', 'fullName'], 'Employee'),
                    style: AppTypography.inter(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _text(profile, const ['employeeCode', 'code'], ''),
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _text(profile, const ['designation'], 'Production'),
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _section('DASHBOARD'),
            _tile('Dashboard', Remix.dashboard_line),
            _section('HRM & WORKPLACE'),
            _tile('Attendance', Remix.fingerprint_line),
            _tile('Requests & Leaves', Remix.calendar_check_line),
            _tile('Expenses & Claims', Remix.wallet_3_line),
            _tile('Remote Work', Remix.home_wifi_line),
            _tile('Salary Slips', Remix.receipt_line),
            _section('SYSTEM'),
            _tile('Settings', Remix.settings_3_line),
            const Divider(),
            ListTile(
              leading: const Icon(Remix.logout_box_r_line),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppConfig.title,
                style: AppTypography.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
    return ListTile(
      leading: Icon(icon, color: active ? AppColors.darkPrimary : null),
      title: Text(
        label,
        style: AppTypography.inter(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? AppColors.darkPrimary : AppColors.textPrimary,
        ),
      ),
      selected: active,
      selectedTileColor: AppColors.lightPrimary,
      onTap: () => onSelect(label),
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
