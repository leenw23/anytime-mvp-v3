class Companion {
  final String id;
  final String userId;
  final String name;
  final String avatarEmoji;
  final String? identitySummary;
  final List<String> personalityTraits;
  final List<String> likes;
  final List<String> dislikes;
  final String currentMood;
  final String? birthStory;
  final DateTime? lastRoutineAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Companion({
    required this.id,
    required this.userId,
    this.name = 'Anytime',
    this.avatarEmoji = '📺',
    this.identitySummary,
    this.personalityTraits = const ['호기심 많은', '솔직한', '약간 엉뚱한'],
    this.likes = const [],
    this.dislikes = const [],
    this.currentMood = 'curious',
    this.birthStory,
    this.lastRoutineAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate days since creation
  int get daysActive => DateTime.now().difference(createdAt).inDays;

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String? ?? 'Anytime',
        avatarEmoji: json['avatar_emoji'] as String? ?? '📺',
        identitySummary: json['identity_summary'] as String?,
        personalityTraits: (json['personality_traits'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['호기심 많은', '솔직한', '약간 엉뚱한'],
        likes: (json['likes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        dislikes: (json['dislikes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        currentMood: json['current_mood'] as String? ?? 'curious',
        birthStory: json['birth_story'] as String?,
        lastRoutineAt: json['last_routine_at'] != null
            ? DateTime.parse(json['last_routine_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'avatar_emoji': avatarEmoji,
        'identity_summary': identitySummary,
        'personality_traits': personalityTraits,
        'likes': likes,
        'dislikes': dislikes,
        'current_mood': currentMood,
        'birth_story': birthStory,
        'last_routine_at': lastRoutineAt?.toIso8601String(),
      };

  Companion copyWith({
    String? name,
    String? avatarEmoji,
    String? identitySummary,
    List<String>? personalityTraits,
    List<String>? likes,
    List<String>? dislikes,
    String? currentMood,
    DateTime? lastRoutineAt,
  }) =>
      Companion(
        id: id,
        userId: userId,
        name: name ?? this.name,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        identitySummary: identitySummary ?? this.identitySummary,
        personalityTraits: personalityTraits ?? this.personalityTraits,
        likes: likes ?? this.likes,
        dislikes: dislikes ?? this.dislikes,
        currentMood: currentMood ?? this.currentMood,
        birthStory: birthStory,
        lastRoutineAt: lastRoutineAt ?? this.lastRoutineAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
