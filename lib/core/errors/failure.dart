/// Represents a domain-level failure from a repository or service call.
///
/// Use [Failure] to propagate error info from the data layer up to the UI
/// without throwing exceptions across layer boundaries.
sealed class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'Failure($code): $message';
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Terjadi kesalahan server'])
      : super(message, code: 'server');
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Gagal memuat dari cache'])
      : super(message, code: 'cache');
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Tidak ada koneksi internet'])
      : super(message, code: 'network');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Gagal autentikasi'])
      : super(message, code: 'auth');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message) : super(code: 'validation');
}
