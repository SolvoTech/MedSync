import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/care_person.dart';
import 'care_person_list_screen.dart';

class CarePersonFormScreen extends ConsumerStatefulWidget {
  const CarePersonFormScreen({super.key, this.existing});
  final CarePerson? existing;

  @override
  ConsumerState<CarePersonFormScreen> createState() =>
      _CarePersonFormScreenState();
}

class _CarePersonFormScreenState extends ConsumerState<CarePersonFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _notesController;
  DateTime? _birthDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasAttemptedSubmit = false;

  bool get _isEditing => widget.existing != null;

  static const _relationshipOptions = [
    'Ayah',
    'Ibu',
    'Kakek',
    'Nenek',
    'Suami',
    'Istri',
    'Anak',
    'Saudara',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.displayName);
    _relationshipController = TextEditingController(
      text: widget.existing?.relationship,
    );
    _notesController = TextEditingController(text: widget.existing?.notes);
    _birthDate = widget.existing?.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (!_hasAttemptedSubmit) {
        setState(() => _hasAttemptedSubmit = true);
      }
      return;
    }

    setState(() => _isSaving = true);
    final ds = ref.read(carePersonDataSourceProvider);

    try {
      if (_isEditing) {
        await ds.updateCarePerson(
          id: widget.existing!.id,
          displayName: _nameController.text.trim(),
          relationship: _relationshipController.text.trim().isEmpty
              ? null
              : _relationshipController.text.trim(),
          birthDate: _birthDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await ds.createCarePerson(
          displayName: _nameController.text.trim(),
          relationship: _relationshipController.text.trim().isEmpty
              ? null
              : _relationshipController.text.trim(),
          birthDate: _birthDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) {
        context.showSuccessSnackBar(
          _isEditing
              ? AppStrings.tr(
                  'Member updated successfully.',
                  'Anggota berhasil diperbarui.',
                )
              : AppStrings.tr(
                  'Member added successfully.',
                  'Anggota berhasil ditambahkan.',
                ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to save data. Please try again.',
              'Gagal menyimpan data. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? AppStrings.tr('Edit Member', 'Edit Anggota')
              : AppStrings.addCarePerson,
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
                label: AppStrings.tr('Display Name', 'Nama Panggilan'),
                hint: 'e.g. Ayah, Ibu, Nenek',
                prefixIcon: const Icon(Icons.person_outline),
                validator: AppValidators.name,
              ),
              const SizedBox(height: 16),

              // Relationship — chip selector
              Text(
                AppStrings.tr('Relationship', 'Hubungan'),
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relationshipOptions.map((option) {
                  final isSelected = _relationshipController.text == option;
                  return ChoiceChip(
                    label: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _relationshipController.text = selected ? option : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Birth date
              AppDateField(
                label: AppStrings.tr('Birth Date', 'Tanggal Lahir'),
                value: _birthDate,
                emptyText: AppStrings.tr('Not filled yet', 'Belum diisi'),
                prefixIcon: Icons.cake_outlined,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 16),

              // Notes
              AppTextField(
                controller: _notesController,
                label: AppStrings.tr('Notes (Optional)', 'Catatan (Opsional)'),
                hint: AppStrings.tr(
                  'Health condition, allergies, etc.',
                  'Kondisi kesehatan, alergi, dll.',
                ),
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes),
                validator: (v) => AppValidators.maxLengthOptional(
                  v,
                  250,
                  label: AppStrings.tr('Notes', 'Catatan'),
                ),
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
