import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/validators/app_validators.dart';
import '../auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (!_hasAttemptedSubmit) {
        setState(() => _hasAttemptedSubmit = true);
      }
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email: _emailController.text);

    final authState = ref.read(authControllerProvider);
    if (!mounted) {
      return;
    }

    authState.whenOrNull(
      data: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email reset kata sandi sudah dikirim.')),
      ),
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim email reset: $error')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.forgotPasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Alamat Email'),
                validator: AppValidators.email,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: Text(
                    isLoading ? AppStrings.loading : 'Kirim Tautan Reset',
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
