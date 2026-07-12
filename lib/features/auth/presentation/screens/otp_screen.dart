import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String purpose;

  const OtpScreen({super.key, required this.mobile, required this.purpose});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _sendOtp() {
    ref.read(otpProvider.notifier).sendOtp(widget.mobile, widget.purpose);
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit OTP'), backgroundColor: AppColors.error),
      );
      return;
    }
    await ref.read(otpProvider.notifier).verifyOtp(
          widget.mobile,
          _otpController.text,
          widget.purpose,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpProvider);

    ref.listen(otpProvider, (_, next) {
      if (next.resetToken != null) {
        context.push('/new-password', extra: {
          'mobile': widget.mobile,
          'reset_token': next.resetToken!,
        });
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(otpProvider.notifier).clearError();
      }
    });

    final maskedMobile =
        '+91 ${widget.mobile.substring(0, 2)}****${widget.mobile.substring(6)}';

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sms_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Enter OTP', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text(
                'We sent a 4-digit code to $maskedMobile',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),

              // OTP boxes
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 4,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    color: AppColors.primaryLight,
                  ),
                  submittedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: AppColors.success),
                    color: AppColors.successLight,
                  ),
                  onCompleted: (_) => _verify(),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: state.isVerifying ? null : _verify,
                child: state.isVerifying
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify OTP'),
              ),

              const SizedBox(height: 20),

              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend OTP in ${_secondsLeft}s',
                        style: AppTextStyles.caption,
                      )
                    : TextButton(
                        onPressed: () {
                          _sendOtp();
                          _startTimer();
                        },
                        child: const Text('Resend OTP'),
                      ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo OTP: 1234',
                        style: AppTextStyles.body.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
