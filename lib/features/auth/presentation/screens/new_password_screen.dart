import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String resetToken;

  const NewPasswordScreen({super.key, required this.mobile, required this.resetToken});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _pw1Ctr    = TextEditingController();
  final _pw2Ctr    = TextEditingController();
  bool _obscure1   = true;
  bool _obscure2   = true;

  @override
  void dispose() { _pw1Ctr.dispose(); _pw2Ctr.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(resetPasswordProvider.notifier)
        .reset(widget.mobile, widget.resetToken, _pw1Ctr.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);

    ref.listen(resetPasswordProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated! Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_reset_outlined, size: 48, color: AppColors.success),
                const SizedBox(height: 16),
                Text('Set new password', style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text('OTP verified ✓ — choose a strong new password.',
                    style: AppTextStyles.body),
                const SizedBox(height: 32),

                AuthTextField(
                  controller: _pw1Ctr,
                  label: 'New password',
                  hint: 'Minimum 8 characters',
                  obscureText: _obscure1,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),

                AuthTextField(
                  controller: _pw2Ctr,
                  label: 'Confirm password',
                  hint: 'Repeat new password',
                  obscureText: _obscure2,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  validator: (v) => Validators.confirmPassword(v, _pw1Ctr.text),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update password & sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
