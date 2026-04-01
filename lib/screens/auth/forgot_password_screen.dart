import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final error = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailCtrl.text);

    if (mounted) {
      setState(() {
        _loading = false;
        if (error == null) _sent = true;
      });
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? _SuccessView()
              : _FormView(
                  emailCtrl: _emailCtrl,
                  loading: _loading,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSubmit;
  const _FormView({
    required this.emailCtrl,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔒', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 24),
        Text(
          'Forgot password?',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your email and we'll send you a reset link.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.col.bg,
                  ),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📧', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent. Check your inbox and follow the instructions.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

/// Shared logo widget used across auth screens.
class _SpotLogo extends StatelessWidget {
  const _SpotLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Xplooria',
          style: TextStyle(
            color: context.col.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
