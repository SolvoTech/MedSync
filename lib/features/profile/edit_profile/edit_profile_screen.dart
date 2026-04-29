import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/user_profile.dart';
import '../profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  DateTime? _birthDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _loaded = false;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile? profile) {
    if (_loaded || profile == null) return;
    _loaded = true;
    _nameController.text = profile.fullName;
    _birthDate = profile.birthDate;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
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
      await ref.read(profileDataSourceProvider).updateProfile({
        'full_name': _nameController.text.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T').first,
      });

      refreshCurrentProfile(ref);

      if (mounted) {
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Profile updated successfully.',
            'Profil berhasil diperbarui.',
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
              'Failed to update profile. Please try again.',
              'Gagal memperbarui profil. Silakan coba lagi.',
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
    final profileAsync = ref.watch(currentProfileProvider);
    final compact = MediaQuery.sizeOf(context).width < 340;

    profileAsync.whenData(_initFromProfile);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.editProfile,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              AppTextField(
                controller: _nameController,
                label: AppStrings.fullNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
                validator: AppValidators.name,
              ),
              const SizedBox(height: 20),

              // Birth date
              AppDateField(
                label: AppStrings.birthDateLabel,
                value: _birthDate,
                emptyText: AppStrings.tr('Not filled yet', 'Belum diisi'),
                prefixIcon: Icons.cake_outlined,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: AppStrings.save,
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
