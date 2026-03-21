import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _passwordStrength() {
    final pwd = _newPasswordController.text;
    if (pwd.isEmpty) return 0;
    double score = 0;
    if (pwd.length >= 8) score += 0.25;
    if (pwd.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) score += 0.2;
    return score.clamp(0, 1);
  }

  String _strengthLabel(double strength) {
    if (strength < 0.3) return AppStrings.tr('Weak', 'Lemah');
    if (strength < 0.6) return AppStrings.tr('Medium', 'Sedang');
    if (strength < 0.8) return AppStrings.tr('Strong', 'Kuat');
    return AppStrings.tr('Very Strong', 'Sangat Kuat');
  }

  Color _strengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.green;
    return Colors.green.shade700;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (!_hasAttemptedSubmit) {
        setState(() => _hasAttemptedSubmit = true);
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Password updated successfully.',
            'Kata sandi berhasil diperbarui.',
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to update password. Please try again.',
              'Gagal memperbarui kata sandi. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.changePassword)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // New password
              AppTextField(
                controller: _newPasswordController,
                label: AppStrings.tr('New Password', 'Kata Sandi Baru'),
                isObscure: _obscureNew,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                onChanged: (_) => setState(() {}),
                validator: AppValidators.strongPassword,
              ),
              const SizedBox(height: 8),

              // Strength indicator
              if (_newPasswordController.text.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: strength,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _strengthColor(strength),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _strengthLabel(strength),
                      style: TextStyle(
                        color: _strengthColor(strength),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr(
                    'Min 8 characters, uppercase letter, and number',
                    'Min 8 karakter, huruf besar, angka',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Confirm password
              AppTextField(
                controller: _confirmPasswordController,
                label: AppStrings.confirmPasswordLabel,
                isObscure: _obscureConfirm,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) => AppValidators.confirmPassword(
                  v,
                  _newPasswordController.text,
                ),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: AppStrings.tr('Update Password', 'Perbarui Kata Sandi'),
                onPressed: _submit,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
