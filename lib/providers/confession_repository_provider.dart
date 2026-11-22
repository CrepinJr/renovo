import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/confession_repository.dart';
import '../services/auth_service.dart';

final confessionRepositoryProvider = Provider<ConfessionRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user == null
        ? LocalConfessionRepository()
        : FirestoreConfessionRepository(uid: user.uid),
    loading: LocalConfessionRepository.new,
    error: (error, stackTrace) => Error.throwWithStackTrace(error, stackTrace),
  );
});
