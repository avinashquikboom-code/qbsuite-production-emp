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

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              physics: const BouncingScrollPhysics(),
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
                    constraints: const BoxConstraints(maxWidth: 480),
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
                              width: 32,
                              height: 1.5,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'EMPLOYEE WORKFORCE PORTAL',
                                    style: AppTypography.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: const Color(0xFF667085),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
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
                            color: const Color(0xFF1D2939),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your login type to continue',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
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
                                  color: const Color(0xFF1D2939),
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
                              if (_emailMode)
                                TextField(
                                  controller: _email,
                                  keyboardType: TextInputType.text,
                                  style: AppTypography.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF101828),
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: 'Enter email or Employee ID',
                                    icon: Remix.mail_line,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Remix.smartphone_line,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '+91',
                                            style: AppTypography.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _email,
                                        keyboardType: TextInputType.phone,
                                        style: AppTypography.inter(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF101828),
                                        ),
                                        decoration: _fieldDecoration(
                                          hint: 'Enter mobile number',
                                          icon: Remix.phone_line,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  _emailMode
                                      ? 'e.g. employee@company.com or EMP-011'
                                      : 'e.g. 9876543210',
                                  style: AppTypography.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              if (_emailMode) ...[
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  style: AppTypography.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF101828),
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: '••••••',
                                    icon: Remix.lock_2_line,
                                    suffix: IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure ? Remix.eye_off_line : Remix.eye_line,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _remember,
                                            activeColor: const Color(0xFF5EC269),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                              width: 1.5,
                                            ),
                                            onChanged: (value) =>
                                                setState(() => _remember = value ?? false),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remember Me',
                                          style: AppTypography.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => _notice(
                                        'Ask your administrator to reset your password.',
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: AppTypography.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF5EC269),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: AppTypography.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                                      colors: [Color(0xFF5EC269), Color(0xFF078A43)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : (_emailMode
                                              ? _signIn
                                              : () => _notice(
                                                  'Mobile OTP is not available in this preview.',
                                                )),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
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
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _emailMode ? 'Sign In' : 'Send OTP',
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
                              const SizedBox(height: 16),
                              const _SecureLoginCard(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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
      prefixIcon: Icon(icon, color: const Color(0xFF5EC269), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF5EC269), width: 1.5),
      ),
    );
  }

  Widget _pill(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF334155)),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecureLoginCard extends StatelessWidget {
  const _SecureLoginCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(Remix.shield_check_fill, color: Color(0xFF5EC269), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Login',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
                Text(
                  'Your data is protected with advanced security',
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Remix.shield_check_line, color: Color(0xFF5EC269), size: 26),
        ],
      ),
    );
  }
}
