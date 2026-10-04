import '../api/json_map.dart';

class MessageThread {
  const MessageThread({
    required this.relatedType,
    required this.relatedId,
    required this.otherUserId,
    this.otherUserName,
    this.lastMessage,
    this.lastSentAt,
    this.unreadCount = 0,
  });

  final String relatedType;
  final String relatedId;
  final String otherUserId;
  final String? otherUserName;
  final String? lastMessage;
  final String? lastSentAt;
  final int unreadCount;

  String get contextLabel {
    switch (relatedType) {
      case 'report':
        return 'Report';
      case 'case':
        return 'Case';
      case 'adoption':
        return 'Adoption';
      default:
        return relatedType;
    }
  }

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      relatedType: (json['related_type'] ?? '').toString(),
      relatedId: (json['related_id'] ?? '').toString(),
      otherUserId: (json['other_user_id'] ?? '').toString(),
      otherUserName: asNullableString(json['other_user_name']),
      lastMessage: asNullableString(json['last_message']),
      lastSentAt: asNullableString(json['last_sent_at']),
      unreadCount: asInt(json['unread_count']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    this.sentAt,
    this.readAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String messageText;
  final String? sentAt;
  final String? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? '').toString(),
      messageText: (json['message_text'] ?? '').toString(),
      sentAt: asNullableString(json['sent_at']),
      readAt: asNullableString(json['read_at']),
    );
  }
}
