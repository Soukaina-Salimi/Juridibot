class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final String? source;
  final String? article;
  final String? category;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isUser,
    this.source,
    this.article,
    this.category,
  });

  factory Message.user(String content) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      isUser: true,
    );
  }

  factory Message.bot(
    String content, {
    String? source,
    String? article,
    String? category,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      isUser: false,
      source: source,
      article: article,
      category: category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isUser': isUser,
      'source': source,
      'article': article,
      'category': category,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isUser: map['isUser'],
      source: map['source'],
      article: map['article'],
      category: map['category'],
    );
  }
}
