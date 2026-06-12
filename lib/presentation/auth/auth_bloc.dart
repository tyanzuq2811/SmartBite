import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final UserProfileEntity profile;

  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.profile,
  });

  @override
  List<Object?> get props => [email, password, profile];
}

class LogoutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class UpdateProfileRequested extends AuthEvent {
  final UserProfileEntity profile;

  const UpdateProfileRequested({required this.profile});

  @override
  List<Object?> get props => [profile];
}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthenticatedUser extends AuthState {
  final UserEntity user;
  const AuthenticatedUser({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthenticatedAdmin extends AuthState {
  final UserEntity user;
  const AuthenticatedAdmin({required this.user});

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {}

// --- BLOC ---
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository userRepository;

  AuthBloc(this.userRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await userRepository.getCurrentUser();
      if (user != null) {
        _emitAuthenticatedState(user, emit);
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await userRepository.login(
        email: event.email,
        password: event.password,
      );
      _emitAuthenticatedState(user, emit);
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '').replaceAll('Failure: ', '')));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await userRepository.register(
        email: event.email,
        password: event.password,
        profile: event.profile,
      );
      _emitAuthenticatedState(user, emit);
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '').replaceAll('Failure: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await userRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await userRepository.resetPassword(event.email);
      emit(PasswordResetSent());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '').replaceAll('Failure: ', '')));
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    UserEntity? currentUser;
    if (currentState is AuthenticatedUser) {
      currentUser = currentState.user;
    } else if (currentState is AuthenticatedAdmin) {
      currentUser = currentState.user;
    }

    if (currentUser == null) return;

    emit(AuthLoading());
    try {
      await userRepository.updateUserProfile(currentUser.userId, event.profile);
      final updatedUser = currentUser.copyWith(profile: event.profile);
      _emitAuthenticatedState(updatedUser, emit);
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _emitAuthenticatedState(UserEntity user, Emitter<AuthState> emit) {
    if (user.role == 'admin') {
      emit(AuthenticatedAdmin(user: user));
    } else {
      emit(AuthenticatedUser(user: user));
    }
  }
}
