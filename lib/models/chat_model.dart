import 'message_model.dart';

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final String? category;
  final bool isPinned;
  final int messageCount;

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.category,
    this.isPinned = false,
    this.messageCount = 0,
  });

  Chat addMessage(Message message) {
    return Chat(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: [...messages, message],
      category: category,
      isPinned: isPinned,
      messageCount: messageCount + 1,
    );
  }

  Chat updateTitle(String newTitle) {
    return Chat(
      id: id,
      title: newTitle,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: messages,
      category: category,
      isPinned: isPinned,
      messageCount: messageCount,
    );
  }

  Chat togglePin() {
    return Chat(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: messages,
      category: category,
      isPinned: !isPinned,
      messageCount: messageCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'category': category,
      'isPinned': isPinned,
      'messageCount': messageCount,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      messages: (map['messages'] as List)
          .map((msg) => Message.fromMap(msg))
          .toList(),
      category: map['category'],
      isPinned: map['isPinned'] ?? false,
      messageCount: map['messageCount'] ?? 0,
    );
  }

  factory Chat.newChat(String initialMessage) {
    final now = DateTime.now();
    return Chat(
      id: now.millisecondsSinceEpoch.toString(),
      title: _generateTitle(initialMessage),
      createdAt: now,
      updatedAt: now,
      messages: [],
      messageCount: 0,
    );
  }

  static String _generateTitle(String message) {
    if (message.length > 30) {
      return '${message.substring(0, 30)}...';
    }
    return message;
  }
}
