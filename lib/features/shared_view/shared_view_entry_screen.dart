import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/validators/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'shared_view_dashboard_screen.dart';

class SharedViewEntryScreen extends StatefulWidget {
  const SharedViewEntryScreen({super.key});

  @override
  State<SharedViewEntryScreen> createState() => _SharedViewEntryScreenState();
}

class _SharedViewEntryScreenState extends State<SharedViewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _hasAttemptedSubmit = true;
        _error = null;
      });
      return;
    }
    final token = _tokenController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'shared-view',
        body: {'token': token},
      );

      if (response.status != 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        throw Exception(data['error'] ?? 'Terjadi kesalahan');
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedViewDashboardScreen(
              token: token,
              data: data as Map<String, dynamic>,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lihat Status')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.share_outlined,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Masukkan Kode Akses',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Caregiver Anda telah membagikan kode akses agar Anda bisa memantau status kesehatan mereka.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _tokenController,
                label: 'Kode Akses',
                hint: 'Contoh: MED-4X7K',
                errorText: _error,
                keyboardType: TextInputType.text,
                prefixIcon: Icon(Icons.vpn_key_outlined),
                validator: AppValidators.accessToken,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Lihat Status',
                onPressed: _verifyToken,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
