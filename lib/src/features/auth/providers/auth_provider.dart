import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
