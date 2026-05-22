import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_form_container.dart';
import 'onboarding_profile_controller.dart';

class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _birthDate;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    final fullName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']
            as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      _nameController.text = fullName.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (!_hasAttemptedSubmit) {
        setState(() => _hasAttemptedSubmit = true);
      }
      return;
    }

    await ref
        .read(onboardingProfileControllerProvider.notifier)
        .saveProfile(fullName: _nameController.text, birthDate: _birthDate);

    if (!mounted) {
      return;
    }

    final state = ref.read(onboardingProfileControllerProvider);
    state.whenOrNull(
      data: (_) => context.go(AppRoutes.home),
      error: (error, _) => context.showErrorSnackBar(
        toUserErrorMessage(error, fallback: AppStrings.saveProfileFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(onboardingProfileControllerProvider);
    final isLoading = saveState.isLoading;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.completeProfileTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppGradients.softSky,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softShadow.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/medsync_hero_medication.png',
                      width: compact ? 72 : 92,
                      height: compact ? 62 : 78,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.tr(
                          'Complete your profile so reminders feel personal.',
                          'Lengkapi profil agar pengingat terasa lebih personal.',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppFormContainer(
                title: AppStrings.basicProfileTitle,
                subtitle: AppStrings.basicProfileSubtitle,
                icon: Icons.person_outline_rounded,
                showHandle: false,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.fullNameLabel,
                      ),
                      validator: AppValidators.name,
                    ),
                    const SizedBox(height: 12),
                    AppDateField(
                      label: AppStrings.birthDateOptional,
                      value: _birthDate,
                      emptyText: AppStrings.notSelected,
                      onTap: _pickBirthDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: Text(
                  isLoading ? AppStrings.saving : AppStrings.saveProfile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
