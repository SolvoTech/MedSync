/// Base exception class for all app-level errors.
///
/// [code] is an internal English identifier (e.g. 'auth/invalid-password').
/// [message] is a user-facing Indonesian error message.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      code != null ? 'AppException($code): $message' : 'AppException: $message';
}

/// Network-specific exception.
class NetworkException extends AppException {
  const NetworkException([String message = 'Tidak ada koneksi internet'])
      : super(message, code: 'network/offline');
}

/// Authentication-specific exception.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Data not found exception.
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Data tidak ditemukan'])
      : super(message, code: 'data/not-found');
}

/// Permission denied exception.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    String message = 'Izin tidak diberikan',
  ]) : super(message, code: 'permission/denied');
}
