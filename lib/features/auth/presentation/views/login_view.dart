import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});
  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _email = TextEditingController(text: 'emp-011');
  final _password = TextEditingController(text: '123456');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppLogo(width: 180),
                        const SizedBox(height: 16),
                        Text(
                          'Production Employee',
                          textAlign: TextAlign.center,
                          style: AppTypography.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'EMPLOYEE WORKSPACE',
                          textAlign: TextAlign.center,
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Employee ID, email, or mobile',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Remix.eye_off_line : Remix.eye_line,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset is handled by your company administrator.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Forgot password'),
                          ),
                        ),
                        if (auth.hasError)
                          Text(
                            auth.error.toString(),
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => ref
                                      .read(authViewModelProvider.notifier)
                                      .signIn(_email.text, _password.text),
                            child: auth.isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
