class Profile {
  final String id; // UUID = auth.uid()
  final String? email;
  final String? displayName;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.email,
    this.displayName,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['display_name'] as String?,
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'onboarding_completed': onboardingCompleted,
      };

  Profile copyWith({
    String? email,
    String? displayName,
    bool? onboardingCompleted,
  }) =>
      Profile(
        id: id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
