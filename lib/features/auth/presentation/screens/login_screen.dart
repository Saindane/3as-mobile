import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_badge.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginProvider.notifier).login(
          _mobileCtr.text.trim(),
          _passwordCtr.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    // Navigate on success
    ref.listen(loginProvider, (_, next) {
      if (next.success) {
        ref.read(authNotifierProvider).setLoggedIn(true);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(loginProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + brand
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.apartment, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('3As Complex', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text('Maintenance Management System',
                          style: AppTextStyles.caption.copyWith(fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                Text('Sign in', style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text('Enter your registered mobile number and password.',
                    style: AppTextStyles.body),

                const SizedBox(height: 24),

                // Mobile
                AuthTextField(
                  controller: _mobileCtr,
                  label: 'Mobile number',
                  hint: '98765 43210',
                  keyboardType: TextInputType.phone,
                  prefixWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text('+91', style: AppTextStyles.bodyBold),
                  ),
                  maxLength: 10,
                  validator: Validators.mobile,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),

                const SizedBox(height: 14),

                // Password
                AuthTextField(
                  controller: _passwordCtr,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/otp',
                        extra: {'mobile': _mobileCtr.text.trim(), 'purpose': 'password_reset'}),
                    child: Text('Forgot password?',
                        style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                  ),
                ),

                const SizedBox(height: 8),

                // Login button
                ElevatedButton(
                  onPressed: loginState.isLoading ? null : _submit,
                  child: loginState.isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sign in'),
                ),

                const SizedBox(height: 32),

                // Divider
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or sign in as demo user', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider()),
                ]),

                const SizedBox(height: 16),

                // Demo accounts
                _DemoCard(
                  initials: 'RK', name: 'Rajesh Kumar',
                  subtitle: 'Resident · Unit 4B · 98765 43210',
                  color: AppColors.primary,
                  onTap: () => _quickLogin('9876543210', 'demo1234'),
                ),
                const SizedBox(height: 8),
                _DemoCard(
                  initials: 'PM', name: 'Priya Menon',
                  subtitle: 'Management · 87654 32109',
                  color: AppColors.warning,
                  onTap: () => _quickLogin('8765432109', 'demo1234'),
                ),
                const SizedBox(height: 8),
                _DemoCard(
                  initials: 'SA', name: 'Suresh Admin',
                  subtitle: 'Administrator · 76543 21098',
                  color: const Color(0xFF7C3AED),
                  onTap: () => _quickLogin('7654321098', 'demo1234'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _quickLogin(String mobile, String password) {
    _mobileCtr.text = mobile;
    _passwordCtr.text = password;
    _submit();
  }
}

class _DemoCard extends StatelessWidget {
  final String initials, name, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.initials, required this.name,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.15),
              child: Text(initials,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
