import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/storage/session_store.dart';
import '../../domain/session.dart';
import '../providers/auth_providers.dart';

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, Session?>(
  AuthViewModel.new,
);

class AuthViewModel extends AsyncNotifier<Session?> {
  bool _busy = false;
  @override
  Future<Session?> build() async {
    final store = ref.watch(sessionStoreProvider);
    final subscription = store.changes.listen((session) {
      if (ref.mounted) state = AsyncData(session);
    });
    ref.onDispose(subscription.cancel);
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<void> signIn(String email, String password) async {
    if (_busy || state.isLoading) return;
    final identifier = email.trim();
    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);
    final isEmployeeId = RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._-]{2,}$',
    ).hasMatch(identifier);
    if ((!isEmail && !isEmployeeId) || password.isEmpty) {
      state = AsyncError(
        const AppFailure('Enter your employee ID, email, or mobile and password.'),
        StackTrace.current,
      );
      return;
    }
    _busy = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(email, password),
    );
    if (ref.mounted) state = result;
    _busy = false;
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard<Session?>(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
    if (ref.mounted) state = result;
    _busy = false;
  }
}
