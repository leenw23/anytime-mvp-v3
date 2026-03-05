import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/routine_service.dart';
import 'auth_provider.dart';

final routineServiceProvider = Provider<RoutineService>((ref) {
  return RoutineService();
});

/// Trigger routine check on app open
final routineCheckProvider = FutureProvider.autoDispose<RoutineResult?>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final token = auth.accessToken;
  if (token == null) return null;

  final service = ref.watch(routineServiceProvider);
  return service.checkAndRun(accessToken: token);
});
