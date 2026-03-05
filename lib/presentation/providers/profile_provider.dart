import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../core/services/auth_service.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileState {
  final Companion? companion;
  final List<UserKnowledge> userKnowledge;
  final List<AiChangeLog> changeLog;
  final bool isLoading;

  const ProfileState({
    this.companion,
    this.userKnowledge = const [],
    this.changeLog = const [],
    this.isLoading = false,
  });

  ProfileState copyWith({
    Companion? companion,
    List<UserKnowledge>? userKnowledge,
    List<AiChangeLog>? changeLog,
    bool? isLoading,
  }) =>
      ProfileState(
        companion: companion ?? this.companion,
        userKnowledge: userKnowledge ?? this.userKnowledge,
        changeLog: changeLog ?? this.changeLog,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repo;
  final AuthService _auth;

  ProfileNotifier(this._repo, this._auth) : super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final userId = _auth.userId;
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final companion = await _repo.getCompanion(userId);
    if (companion == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final knowledge = await _repo.getUserKnowledge(companion.id);
    final log = await _repo.getChangeLog(companion.id);

    state = state.copyWith(
      companion: companion,
      userKnowledge: knowledge,
      changeLog: log,
      isLoading: false,
    );
  }

  Future<void> updateAvatar(String emoji) async {
    if (state.companion == null) return;
    await _repo.updateCompanionAvatar(state.companion!.id, emoji);
    state = state.copyWith(
        companion: state.companion!.copyWith(avatarEmoji: emoji));
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final auth = ref.watch(authServiceProvider);
  return ProfileNotifier(repo, auth);
});
