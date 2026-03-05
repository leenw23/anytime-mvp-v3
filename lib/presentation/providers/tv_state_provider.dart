import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TvState { idle, listening, speaking, pending, thinking }

final tvStateProvider = StateProvider<TvState>((ref) => TvState.idle);
