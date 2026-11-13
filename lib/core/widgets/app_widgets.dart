import 'package:flutter/material.dart';

import '../icons/remix_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'responsive/responsive.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: loading
        ? const SizedBox.square(dimension: 20, child: AppLoader())
        : Text(label),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.autofillHints,
  });
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    onChanged: onChanged,
    autofillHints: autofillHints,
    autocorrect: !obscureText,
    enableSuggestions: !obscureText,
    decoration: InputDecoration(labelText: label),
  );
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
  });
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    icon: const RemixIcon(AppIcon.down),
    items: items,
    onChanged: onChanged,
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'));
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width = 240, this.height = 78});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    semanticLabel: 'QB Suite logo',
  );
}

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: QbSplashBody(),
  );
}

class QbSplashBody extends StatelessWidget {
  const QbSplashBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'QB Suite Production',
              style: AppTypography.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Business Suite',
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            AppButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.title, this.message});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RemixIcon(AppIcon.empty, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) Text(message!, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, required this.onChanged, this.controller});
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: const InputDecoration(
      labelText: 'Search',
      prefixIcon: RemixIcon(AppIcon.search),
    ),
  );
}

abstract final class AppDialog {
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Confirm',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.index,
    required this.onSelected,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => ResponsiveBottomNavigation(
    index: index,
    onSelected: onSelected,
    destinations: const [
      NavigationDestination(icon: RemixIcon(AppIcon.home), label: 'Home'),
      NavigationDestination(
        icon: RemixIcon(AppIcon.notifications),
        label: 'Notifications',
      ),
      NavigationDestination(icon: RemixIcon(AppIcon.profile), label: 'Profile'),
    ],
  );
}

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({super.key, required this.title, this.onBack, this.actions});
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    automaticallyImplyLeading: false,
    actions: actions,
    leading: onBack == null
        ? null
        : IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const RemixIcon(AppIcon.back),
          ),
  );
}
