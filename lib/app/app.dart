import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: AppConfig.title,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(appRouterProvider),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final widthScale = (media.size.width / 390).clamp(0.86, 1.06);
      final scale = (media.textScaler.scale(1) * widthScale).clamp(0.86, 1.2);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(scale)),
        child: IconTheme(
          data: IconThemeData(size: 20 * widthScale, color: AppColors.textPrimary),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
}
