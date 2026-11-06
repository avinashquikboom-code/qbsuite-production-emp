import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    final auth = ref.read(authViewModelProvider);
    if (auth.isLoading) {
      _timer = Timer(const Duration(milliseconds: 300), _continue);
      return;
    }
    context.go(auth.asData?.value == null ? '/login' : '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo_brand.png',
              width: 220,
              height: 120,
              fit: BoxFit.contain,
              semanticLabel: 'QB Suite logo',
            ),
            const SizedBox(height: 24),
            Text(
              'QB SUITE',
              style: AppTypography.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
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
