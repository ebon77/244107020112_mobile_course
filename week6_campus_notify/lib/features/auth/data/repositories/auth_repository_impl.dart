import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const LocalFailure('Email atau kata sandi tidak valid'),
        );
      }
      final model = AuthSessionModel(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
      );
      return (session: model.toEntity(), failure: null);
    } catch (e) {
      return (session: null, failure: LocalFailure('$e'));
    }
  }

  @override
  Future<({String? renewedToken, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (refreshToken.isEmpty) {
        return (
          renewedToken: null,
          failure: const LocalFailure('Refresh token hilang'),
        );
      }
      return (
        renewedToken:
            'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
        failure: null,
      );
    } catch (e) {
      return (renewedToken: null, failure: LocalFailure('$e'));
    }
  }
}
