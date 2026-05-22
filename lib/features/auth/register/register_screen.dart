import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        .signUp(
          fullName: _fullNameController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );

    final authState = ref.read(authControllerProvider);
    if (!mounted) return;

    if (authState.hasError) {
      context.showErrorSnackBar(
        toUserErrorMessage(
          authState.error!,
          fallback: AppStrings.registerFailed,
        ),
      );
      return;
    }

    context.showSuccessSnackBar(AppStrings.registerSuccess);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaSize = MediaQuery.sizeOf(context);
    final compactWidth = mediaSize.width < 340;
    final compactHeight = mediaSize.height < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient top decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mediaSize.height * (compactHeight ? 0.32 : 0.35),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(34),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compactWidth ? 16 : 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _hasAttemptedSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: compactHeight ? 6 : 12),

                      // App logo in frosted container
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compactHeight ? 8 : 12),

                      // Title + subtitle (on gradient)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: compactHeight ? 12 : 20,
                        ),
                        child: Text(
                          AppStrings.registerTitle,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        AppStrings.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.registerGreeting,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: compactHeight ? 18 : 28),

                      // Form card
                      Container(
                        padding: EdgeInsets.all(compactWidth ? 18 : 24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.softShadow.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                          border: isDark
                              ? Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full name
                            AppTextField(
                              controller: _fullNameController,
                              label: AppStrings.fullNameLabel,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: AppValidators.name,
                              useAuthSubtleStyle: true,
                            ),
                            const SizedBox(height: 16),

                            // Username
                            AppTextField(
                              controller: _usernameController,
                              label: AppStrings.usernameLabel,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.alternate_email),
                              validator: AppValidators.username,
                              useAuthSubtleStyle: true,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            AppTextField(
                              controller: _passwordController,
                              label: AppStrings.passwordLabel,
                              isObscure: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              validator: AppValidators.passwordMin8,
                              useAuthSubtleStyle: true,
                            ),
                            const SizedBox(height: 16),

                            // Confirm password
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: AppStrings.confirmPasswordLabel,
                              isObscure: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  );
                                },
                              ),
                              validator: (value) =>
                                  AppValidators.confirmPassword(
                                    value,
                                    _passwordController.text,
                                  ),
                              useAuthSubtleStyle: true,
                            ),
                            const SizedBox(height: 24),

                            // Register button
                            AppButton(
                              label: AppStrings.registerButton,
                              onPressed: _submit,
                              isLoading: isLoading,
                              useGradient: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 2,
                        children: [
                          Text(
                            AppStrings.hasAccount,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: Text(AppStrings.loginLink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
