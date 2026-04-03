import '../constants/app_strings.dart';

class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_]{3,24}$');
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

  static String? username(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) {
      return AppStrings.usernameRequired;
    }
    if (!_usernameRegex.hasMatch(raw)) {
      return AppStrings.usernameInvalid;
    }
    return null;
  }

  static String? name(String? value, {int minLength = 2}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (raw.length < minLength) {
      return AppStrings.tr(
        'Name must be at least $minLength characters',
        'Nama minimal $minLength karakter',
      );
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
      return AppStrings.tr(
        'Must include an uppercase letter and a number',
        'Wajib mengandung huruf besar dan angka',
      );
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
    String? requiredMessage,
    String? invalidMessage,
    String? negativeMessage,
  }) {
    final raw = value?.trim() ?? '';
    final effectiveRequiredMessage =
        requiredMessage ?? AppStrings.fieldRequired;
    final effectiveInvalidMessage =
        invalidMessage ??
        AppStrings.tr('Value must be a number', 'Nilai harus berupa angka');
    final effectiveNegativeMessage =
        negativeMessage ??
        AppStrings.tr('Value cannot be negative', 'Nilai tidak boleh negatif');

    if (raw.isEmpty) {
      return effectiveRequiredMessage;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return effectiveInvalidMessage;
    }
    if (parsed < 0) {
      return effectiveNegativeMessage;
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
      return AppStrings.tr(
        '$label must be at most $maxLength characters',
        '$label maksimal $maxLength karakter',
      );
    }
    return null;
  }

  static String? accessToken(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return AppStrings.tr('Enter access code', 'Masukkan kode akses');
    }
    if (!_accessTokenRegex.hasMatch(raw)) {
      return AppStrings.tr(
        'Invalid access code format',
        'Format kode akses tidak valid',
      );
    }
    return null;
  }
}
