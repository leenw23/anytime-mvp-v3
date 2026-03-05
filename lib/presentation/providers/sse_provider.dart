import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sse_service.dart';

final sseServiceProvider = Provider<SseService>((ref) {
  return SseService();
});
