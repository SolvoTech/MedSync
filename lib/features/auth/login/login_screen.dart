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
import '../onboarding_profile/onboarding_profile_controller.dart';
import '../auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
        .signIn(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    final authState = ref.read(authControllerProvider);
    if (!mounted) return;

    if (authState.hasError) {
      context.showErrorSnackBar(
        toUserErrorMessage(authState.error!, fallback: AppStrings.loginFailed),
      );
      return;
    }

    final hasProfile = await ref.read(currentUserHasProfileProvider.future);
    if (!mounted) return;
    context.go(hasProfile ? AppRoutes.home : AppRoutes.onboardingProfile);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = screenHeight < 760
        ? screenHeight * 0.43
        : screenHeight * 0.38;
    final topSpacing = screenHeight < 760 ? 6.0 : 10.0;
    final headerToCardSpacing = screenHeight < 760 ? 20.0 : 28.0;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient top decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: _hasAttemptedSubmit
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: topSpacing),

                    // App icon in frosted container
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/app_logo.jpeg',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title + subtitle (on gradient)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        AppStrings.loginTitle,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      AppStrings.loginSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.loginGreeting,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),

                    SizedBox(height: headerToCardSpacing),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0F1419,
                                  ).withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
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
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: AppValidators.required,
                            useAuthSubtleStyle: true,
                          ),
                          const SizedBox(height: 4),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.forgotPassword),
                              child: Text(AppStrings.forgotPassword),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Login button
                          AppButton(
                            label: AppStrings.loginButton,
                            onPressed: _submit,
                            isLoading: isLoading,
                            useGradient: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.noAccount,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: Text(AppStrings.registerLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
