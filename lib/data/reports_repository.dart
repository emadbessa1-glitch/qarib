import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع المحتوى اللي اتبلّغ عنه.
enum ReportTarget {
  review('review', 'تقييم'),
  message('message', 'رسالة'),
  chat('chat', 'محادثة'),
  place('place', 'مكان');

  const ReportTarget(this.id, this.label);
  final String id;
  final String label;

  static ReportTarget fromId(String? id) => ReportTarget.values
      .firstWhere((t) => t.id == id, orElse: () => ReportTarget.place);
}

/// أسباب الإبلاغ اللي بتظهر للمستخدم.
const List<String> reportReasons = <String>[
  'كلام مسيء أو شتيمة',
  'نصب أو احتيال',
  'إزعاج أو رسايل كتير',
  'محتوى مش لائق',
  'بيانات غلط',
  'سبب تاني',
];

class Report {
  const Report({
    required this.id,
    required this.target,
    required this.reason,
    required this.reporterId,
    required this.createdAt,
    this.placeId = '',
    this.chatId = '',
    this.itemId = '',
    this.reportedUserId = '',
    this.excerpt = '',
  });

  final String id;
  final ReportTarget target;
  final String reason;
  final String reporterId;
  final DateTime createdAt;

  /// المكان اللي المحتوى تبعه.
  final String placeId;
  final String chatId;

  /// رقم التقييم أو الرسالة.
  final String itemId;
  final String reportedUserId;

  /// نسخة من النص اللي اتبلّغ عنه، عشان الأدمن يحكم من غير ما يفتح المحادثة كلها.
  final String excerpt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'target': target.id,
        'reason': reason,
        'reporterId': reporterId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'placeId': placeId,
        'chatId': chatId,
        'itemId': itemId,
        'reportedUserId': reportedUserId,
        'excerpt': excerpt.length > 500 ? excerpt.substring(0, 500) : excerpt,
      };

  factory Report.fromMap(String id, Map<String, dynamic> m) => Report(
        id: id,
        target: ReportTarget.fromId(m['target'] as String?),
        reason: (m['reason'] ?? '') as String,
        reporterId: (m['reporterId'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
        placeId: (m['placeId'] ?? '') as String,
        chatId: (m['chatId'] ?? '') as String,
        itemId: (m['itemId'] ?? '') as String,
        reportedUserId: (m['reportedUserId'] ?? '') as String,
        excerpt: (m['excerpt'] ?? '') as String,
      );
}

/// البلاغات: أي حد يبلّغ، والأدمن بس يشوف ويتصرف.
abstract class ReportsRepository {
  Future<void> submit(Report report);
  Stream<List<Report>> watchOpen();

  /// الأدمن قفل البلاغ (اتصرف فيه أو مالوش لازمة).
  Future<void> dismiss(String reportId);

  /// الأدمن بيمسح المحتوى نفسه.
  Future<void> deleteReview(String placeId, String reviewId);
  Future<void> deleteMessage(String chatId, String messageId);
}

class DemoReportsRepository implements ReportsRepository {
  final List<Report> _reports = <Report>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 1;

  /// للاختبارات: إيه اللي الأدمن مسحه.
  final List<String> deleted = <String>[];

  List<Report> _sorted() => List<Report>.of(_reports)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> submit(Report report) async {
    _reports.add(Report(
      id: 'r${_next++}',
      target: report.target,
      reason: report.reason,
      reporterId: report.reporterId,
      createdAt: report.createdAt,
      placeId: report.placeId,
      chatId: report.chatId,
      itemId: report.itemId,
      reportedUserId: report.reportedUserId,
      excerpt: report.excerpt,
    ));
    _changes.add(null);
  }

  @override
  Stream<List<Report>> watchOpen() async* {
    yield _sorted();
    yield* _changes.stream.map((_) => _sorted());
  }

  @override
  Future<void> dismiss(String reportId) async {
    _reports.removeWhere((r) => r.id == reportId);
    _changes.add(null);
  }

  @override
  Future<void> deleteReview(String placeId, String reviewId) async =>
      deleted.add('review:$placeId/$reviewId');

  @override
  Future<void> deleteMessage(String chatId, String messageId) async =>
      deleted.add('message:$chatId/$messageId');
}

class FirestoreReportsRepository implements ReportsRepository {
  FirestoreReportsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> submit(Report report) =>
      _db.collection('reports').add(report.toMap());

  @override
  Stream<List<Report>> watchOpen() => _db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Report.fromMap(d.id, d.data()))
          .toList(growable: false));

  @override
  Future<void> dismiss(String reportId) =>
      _db.collection('reports').doc(reportId).delete();

  @override
  Future<void> deleteReview(String placeId, String reviewId) => _db
      .collection('places')
      .doc(placeId)
      .collection('reviews')
      .doc(reviewId)
      .delete();

  @override
  Future<void> deleteMessage(String chatId, String messageId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(messageId)
      .delete();
}
