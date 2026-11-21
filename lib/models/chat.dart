/// محادثة بين مستخدم وصاحب مكان. واحدة بس لكل (مكان + مستخدم).
class Chat {
  const Chat({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.ownerId,
    required this.userId,
    required this.userName,
    this.lastMessage = '',
    this.lastSenderId,
    this.updatedAt,
  });

  final String id;
  final String placeId;
  final String placeName;
  final String ownerId;
  final String userId;
  final String userName;
  final String lastMessage;
  final String? lastSenderId;
  final DateTime? updatedAt;

  static String idFor(String placeId, String userId) => '${placeId}_$userId';

  /// اسم الطرف التاني اللي بيظهر في قائمة المحادثات.
  String titleFor(String myId) => myId == ownerId ? userName : placeName;

  /// آخر رسالة من الطرف التاني (يعني مستني رد مني).
  bool awaitingReplyFrom(String myId) =>
      lastSenderId != null && lastSenderId != myId;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'placeId': placeId,
        'placeName': placeName,
        'ownerId': ownerId,
        'userId': userId,
        'userName': userName,
        'lastMessage': lastMessage,
        'lastSenderId': lastSenderId,
        'updatedAt': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      };

  factory Chat.fromMap(String id, Map<String, dynamic> map) => Chat(
        id: id,
        placeId: (map['placeId'] ?? '') as String,
        placeName: (map['placeName'] ?? '') as String,
        ownerId: (map['ownerId'] ?? '') as String,
        userId: (map['userId'] ?? '') as String,
        userName: (map['userName'] ?? '') as String,
        lastMessage: (map['lastMessage'] ?? '') as String,
        lastSenderId: map['lastSenderId'] as String?,
        updatedAt: map['updatedAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['updatedAt'] as num).toInt())
            : null,
      );

  Chat copyWith({String? lastMessage, String? lastSenderId, DateTime? updatedAt}) =>
      Chat(
        id: id,
        placeId: placeId,
        placeName: placeName,
        ownerId: ownerId,
        userId: userId,
        userName: userName,
        lastMessage: lastMessage ?? this.lastMessage,
        lastSenderId: lastSenderId ?? this.lastSenderId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        senderId: (map['senderId'] ?? '') as String,
        text: (map['text'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
}
