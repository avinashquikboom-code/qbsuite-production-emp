import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_widgets.dart';
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: QbSplashBody(),
    );
  }
}
