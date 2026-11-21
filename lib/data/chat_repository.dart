import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/place.dart';

/// الشات جوه التطبيق بين المستخدم وصاحب المكان.
///
/// Firestore:
///   chats/{placeId_userId}             ← بيانات المحادثة + آخر رسالة
///   chats/{placeId_userId}/messages/x  ← الرسايل
abstract class ChatRepository {
  /// بيفتح المحادثة (أو يعملها لو أول مرة) ويرجّع رقمها.
  Future<String> openChat({
    required Place place,
    required String userId,
    required String userName,
  });

  /// كل محادثاتي سواء أنا المستخدم أو صاحب المكان (الأحدث الأول).
  Stream<List<Chat>> watchMyChats(String myId);

  Stream<Chat?> watchChat(String chatId);

  /// الرسايل من الأقدم للأحدث.
  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> send(String chatId, String senderId, String text);
}

List<Chat> _sortChats(Iterable<Chat> chats) {
  final list = chats.toList()
    ..sort((a, b) => (b.updatedAt ?? DateTime(0))
        .compareTo(a.updatedAt ?? DateTime(0)));
  return list;
}

class DemoChatRepository implements ChatRepository {
  final Map<String, Chat> _chats = <String, Chat>{};
  final Map<String, List<ChatMessage>> _messages = <String, List<ChatMessage>>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Future<String> openChat({
    required Place place,
    required String userId,
    required String userName,
  }) async {
    final id = Chat.idFor(place.id, userId);
    _chats.putIfAbsent(
      id,
      () => Chat(
        id: id,
        placeId: place.id,
        placeName: place.name,
        ownerId: place.ownerId ?? '',
        userId: userId,
        userName: userName,
        updatedAt: DateTime.now(),
      ),
    );
    _changes.add(null);
    return id;
  }

  @override
  Stream<List<Chat>> watchMyChats(String myId) => _watch(() => _sortChats(
        _chats.values.where((c) => c.userId == myId || c.ownerId == myId),
      ));

  @override
  Stream<Chat?> watchChat(String chatId) => _watch(() => _chats[chatId]);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      _watch(() => List<ChatMessage>.of(_messages[chatId] ?? const []));

  @override
  Future<void> send(String chatId, String senderId, String text) async {
    final chat = _chats[chatId];
    if (chat == null) throw StateError('المحادثة مش موجودة');
    final now = DateTime.now();
    (_messages[chatId] ??= <ChatMessage>[]).add(ChatMessage(
      id: 'm${_nextId++}',
      senderId: senderId,
      text: text,
      createdAt: now,
    ));
    _chats[chatId] =
        chat.copyWith(lastMessage: text, lastSenderId: senderId, updatedAt: now);
    _changes.add(null);
  }
}

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  @override
  Future<String> openChat({
    required Place place,
    required String userId,
    required String userName,
  }) async {
    final id = Chat.idFor(place.id, userId);
    final ref = _chats.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(Chat(
        id: id,
        placeId: place.id,
        placeName: place.name,
        ownerId: place.ownerId ?? '',
        userId: userId,
        userName: userName,
        updatedAt: DateTime.now(),
      ).toMap());
    }
    return id;
  }

  @override
  Stream<List<Chat>> watchMyChats(String myId) {
    // استعلامين (أنا المستخدم / أنا صاحب المكان) وبندمجهم.
    late StreamController<List<Chat>> controller;
    var asUser = <Chat>[];
    var asOwner = <Chat>[];
    final subs = <StreamSubscription<dynamic>>[];

    List<Chat> parse(QuerySnapshot<Map<String, dynamic>> s) =>
        s.docs.map((d) => Chat.fromMap(d.id, d.data())).toList();
    void emit() => controller.add(_sortChats(<String, Chat>{
          for (final c in [...asUser, ...asOwner]) c.id: c,
        }.values));

    controller = StreamController<List<Chat>>(
      onListen: () {
        subs
          ..add(_chats.where('userId', isEqualTo: myId).snapshots().listen(
                (s) {
                  asUser = parse(s);
                  emit();
                },
                onError: controller.addError,
              ))
          ..add(_chats.where('ownerId', isEqualTo: myId).snapshots().listen(
                (s) {
                  asOwner = parse(s);
                  emit();
                },
                onError: controller.addError,
              ));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Stream<Chat?> watchChat(String chatId) => _chats
      .doc(chatId)
      .snapshots()
      .map((d) => d.exists ? Chat.fromMap(d.id, d.data()!) : null);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ChatMessage.fromMap(d.id, d.data()))
          .toList(growable: false));

  @override
  Future<void> send(String chatId, String senderId, String text) {
    final now = DateTime.now();
    final chatRef = _chats.doc(chatId);
    final batch = _db.batch()
      ..set(
        chatRef.collection('messages').doc(),
        ChatMessage(id: '', senderId: senderId, text: text, createdAt: now)
            .toMap(),
      )
      ..update(chatRef, <String, dynamic>{
        'lastMessage': text.length > 100 ? '${text.substring(0, 100)}…' : text,
        'lastSenderId': senderId,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    return batch.commit();
  }
}
