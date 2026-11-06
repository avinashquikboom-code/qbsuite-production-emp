import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/session.dart';
import '../../../../core/storage/session_store.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});
  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _email = TextEditingController(text: 'emp-011');
  final _password = TextEditingController(text: '123456');
  bool _obscure = true;
  bool _remember = true;
  bool _emailMode = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final raw = _email.text.trim();
    final compact = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (compact != 'emp011' || _password.text != '123456') {
      setState(() => _error = 'Invalid employee ID or password');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    await ref.read(sessionStoreProvider).save(
      const Session(
        accessToken: 'ui-only',
        email: 'emp-011',
        role: 'EMPLOYEE',
      ),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                compact ? 8 : 20,
                compact ? 12 : 20,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 24 : 36),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Image.asset(
                          'assets/images/app_logo_brand.png',
                          height: 68,
                          fit: BoxFit.contain,
                          semanticLabel: 'QB Suite logo',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 1.5,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'EMPLOYEE WORKFORCE PORTAL',
                                    style: AppTypography.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: const Color(0xFF667085),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 1.5,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Login to Your Account',
                          style: AppTypography.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: const Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE8EEF4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login with',
                                style: AppTypography.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _pill(
                                      'Email / EMP-ID',
                                      Remix.mail_line,
                                      _emailMode,
                                      () => setState(() => _emailMode = true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _pill(
                                      'Mobile',
                                      Remix.phone_line,
                                      !_emailMode,
                                      () => setState(() => _emailMode = false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _email,
                                keyboardType: _emailMode
                                    ? TextInputType.text
                                    : TextInputType.phone,
                                decoration: _fieldDecoration(
                                  hint: _emailMode
                                      ? 'Enter email or Employee ID'
                                      : 'Enter mobile number',
                                  icon: _emailMode
                                      ? Remix.mail_line
                                      : Remix.phone_line,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _emailMode
                                    ? 'e.g. employee@company.com or EMP-011'
                                    : 'e.g. 9876543210',
                                style: AppTypography.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: _fieldDecoration(
                                  hint: '••••••',
                                  icon: Remix.lock_2_line,
                                  suffix: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Remix.eye_off_line
                                          : Remix.eye_line,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _remember,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) => setState(
                                        () => _remember = value ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember Me',
                                    style: AppTypography.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ask your administrator to reset your password.',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: AppTypography.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: compact ? 46 : 50,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.darkPrimary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: AppTypography.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Remix.arrow_right_line,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.inter(fontSize: 14, color: const Color(0xFF98A2B3)),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _pill(String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF334155)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
