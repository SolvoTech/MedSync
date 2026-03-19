import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Anggota berhasil diperbarui.'
                  : 'Anggota berhasil ditambahkan.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Anggota' : AppStrings.addCarePerson),
      ),
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
              // Name
              AppTextField(
                controller: _nameController,
                label: 'Nama Panggilan',
                hint: 'e.g. Ayah, Ibu, Nenek',
                prefixIcon: const Icon(Icons.person_outline),
                validator: AppValidators.name,
              ),
              const SizedBox(height: 16),

              // Relationship — chip selector
              Text('Hubungan', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relationshipOptions.map((option) {
                  final isSelected = _relationshipController.text == option;
                  return ChoiceChip(
                    label: Text(option),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.cake_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: const Text('Tanggal Lahir'),
                subtitle: Text(
                  _birthDate != null
                      ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                      : 'Belum diisi',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 16),

              // Notes
              AppTextField(
                controller: _notesController,
                label: 'Catatan (Opsional)',
                hint: 'Kondisi kesehatan, alergi, dll.',
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes),
                validator: (v) =>
                    AppValidators.maxLengthOptional(v, 250, label: 'Catatan'),
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
