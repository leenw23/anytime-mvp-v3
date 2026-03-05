enum MilestoneType {
  firstMeeting,
  nameChosen,
  newDiscovery,
  deepConversation,
  funny,
  insight,
  comfort,
  special,
}

enum MilestoneCreator { ai, user }

extension MilestoneTypeX on MilestoneType {
  String get value {
    switch (this) {
      case MilestoneType.firstMeeting:
        return 'first_meeting';
      case MilestoneType.nameChosen:
        return 'name_chosen';
      case MilestoneType.newDiscovery:
        return 'new_discovery';
      case MilestoneType.deepConversation:
        return 'deep_conversation';
      case MilestoneType.funny:
        return 'funny';
      case MilestoneType.insight:
        return 'insight';
      case MilestoneType.comfort:
        return 'comfort';
      case MilestoneType.special:
        return 'special';
    }
  }

  static MilestoneType fromString(String value) {
    switch (value) {
      case 'first_meeting':
        return MilestoneType.firstMeeting;
      case 'name_chosen':
        return MilestoneType.nameChosen;
      case 'new_discovery':
        return MilestoneType.newDiscovery;
      case 'deep_conversation':
        return MilestoneType.deepConversation;
      case 'funny':
        return MilestoneType.funny;
      case 'insight':
        return MilestoneType.insight;
      case 'comfort':
        return MilestoneType.comfort;
      case 'special':
      default:
        return MilestoneType.special;
    }
  }
}

extension MilestoneCreatorX on MilestoneCreator {
  String get value {
    switch (this) {
      case MilestoneCreator.ai:
        return 'ai';
      case MilestoneCreator.user:
        return 'user';
    }
  }

  static MilestoneCreator fromString(String value) {
    switch (value) {
      case 'user':
        return MilestoneCreator.user;
      case 'ai':
      default:
        return MilestoneCreator.ai;
    }
  }
}

class Milestone {
  final String id;
  final String userId;
  final String companionId;
  final MilestoneType type;
  final MilestoneCreator creator;
  final String? title;
  final String? description;
  final String? messageId;
  final String? conversationId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Milestone({
    required this.id,
    required this.userId,
    required this.companionId,
    required this.type,
    this.creator = MilestoneCreator.ai,
    this.title,
    this.description,
    this.messageId,
    this.conversationId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        companionId: json['companion_id'] as String,
        type: MilestoneTypeX.fromString(
            json['type'] as String? ?? 'special'),
        creator: MilestoneCreatorX.fromString(
            json['creator'] as String? ?? 'ai'),
        title: json['title'] as String?,
        description: json['description'] as String?,
        messageId: json['message_id'] as String?,
        conversationId: json['conversation_id'] as String?,
        metadata:
            (json['metadata'] as Map<String, dynamic>?) ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'companion_id': companionId,
        'type': type.value,
        'creator': creator.value,
        'title': title,
        'description': description,
        'message_id': messageId,
        'conversation_id': conversationId,
        'metadata': metadata,
      };
}
