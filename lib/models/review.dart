class Review {
  const Review({
    required this.id,
    required this.placeId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.authorId,
  });

  final String id;
  final String placeId;
  final String authorName;

  /// من 1 لـ 5.
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? authorId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeId': placeId,
      'authorName': authorName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'authorId': authorId,
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      placeId: (map['placeId'] ?? '') as String,
      authorName: (map['authorName'] ?? '') as String,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: (map['comment'] ?? '') as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
      authorId: map['authorId'] as String?,
    );
  }
}
