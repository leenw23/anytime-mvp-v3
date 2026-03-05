import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/chat_repository.dart';
import 'auth_provider.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(supabaseClientProvider));
});

class HistoryState {
  final List<HistoryItem> items;
  final bool isLoading;

  const HistoryState({this.items = const [], this.isLoading = false});

  HistoryState copyWith({List<HistoryItem>? items, bool? isLoading}) =>
      HistoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repo;
  final ChatRepository _chatRepo;
  final AuthService _auth;

  HistoryNotifier(this._repo, this._chatRepo, this._auth)
      : super(const HistoryState());

  Future<void> load() async {
    final userId = _auth.userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    final companion = await _chatRepo.getCompanion(userId);
    if (companion == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final items = await _repo.getHistory(companion.id);
    state = state.copyWith(items: items, isLoading: false);
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final historyRepo = ref.watch(historyRepositoryProvider);
  final chatRepo = ChatRepository(ref.watch(supabaseClientProvider));
  final auth = ref.watch(authServiceProvider);
  return HistoryNotifier(historyRepo, chatRepo, auth);
});
