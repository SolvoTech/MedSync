import '../constants/app_strings.dart';

class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _accessTokenRegex = RegExp(r'^[A-Za-z0-9-]{4,64}$');

  static String? required(String? value, {String? message}) {
    if ((value ?? '').trim().isEmpty) {
      return message ?? AppStrings.fieldRequired;
    }
    return null;
  }

  static String? email(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!_emailRegex.hasMatch(raw)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  static String? name(String? value, {int minLength = 2}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (raw.length < minLength) {
      return 'Nama minimal $minLength karakter';
    }
    return null;
  }

  static String? passwordMin8(String? value) {
    final raw = value ?? '';
    if (raw.length < 8) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? strongPassword(String? value) {
    final raw = value ?? '';
    final min8Error = passwordMin8(raw);
    if (min8Error != null) {
      return min8Error;
    }
    if (!RegExp(r'[A-Z]').hasMatch(raw) || !RegExp(r'[0-9]').hasMatch(raw)) {
      return 'Wajib mengandung huruf besar dan angka';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if ((value ?? '').isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != originalPassword) {
      return AppStrings.passwordMismatch;
    }
    return null;
  }

  static String? nonNegativeInt(
    String? value, {
    String requiredMessage = 'Bidang ini wajib diisi',
    String invalidMessage = 'Nilai harus berupa angka',
    String negativeMessage = 'Nilai tidak boleh negatif',
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return requiredMessage;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return invalidMessage;
    }
    if (parsed < 0) {
      return negativeMessage;
    }
    return null;
  }

  static String? maxLengthOptional(
    String? value,
    int maxLength, {
    required String label,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.length > maxLength) {
      return '$label maksimal $maxLength karakter';
    }
    return null;
  }

  static String? accessToken(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Masukkan kode akses';
    }
    if (!_accessTokenRegex.hasMatch(raw)) {
      return 'Format kode akses tidak valid';
    }
    return null;
  }
}
