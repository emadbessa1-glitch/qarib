import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place.dart';
import '../models/review.dart';
import 'places_repository.dart';

/// بيانات حقيقية على Cloud Firestore.
///
/// الشكل:
///   places/{placeId}                 ← بيانات المكان + status + ratingSum/ratingCount
///   places/{placeId}/reviews/{id}    ← التقييمات
class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection('places');

  List<Place> _toPlaces(QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
      .map((d) => Place.fromMap(d.id, d.data()))
      .toList(growable: false);

  @override
  Stream<List<Place>> watchApproved() => _places
      .where('status', isEqualTo: PlaceStatus.approved.id)
      .snapshots()
      .map(_toPlaces);

  @override
  Stream<List<Place>> watchPending() => _places
      .where('status', isEqualTo: PlaceStatus.pending.id)
      .snapshots()
      .map(_toPlaces);

  @override
  Stream<List<Review>> watchReviews(String placeId) => _places
      .doc(placeId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Review.fromMap(d.id, d.data()))
          .toList(growable: false));

  @override
  Future<void> submitPlace(Place place) async {
    final data = place.copyWith(status: PlaceStatus.pending).toMap()
      ..['ratingSum'] = 0
      ..['ratingCount'] = 0;
    await _places.add(data);
  }

  @override
  Future<void> setStatus(String placeId, PlaceStatus status) {
    return _places.doc(placeId).update(<String, dynamic>{'status': status.id});
  }

  @override
  Stream<List<Place>> watchMine(String ownerId) => _places
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map(_toPlaces);

  @override
  Future<void> updateWhatsapp(String placeId, String whatsapp) {
    return _places
        .doc(placeId)
        .update(<String, dynamic>{'whatsapp': whatsapp});
  }

  @override
  Future<void> deletePlace(String placeId) => _places.doc(placeId).delete();

  @override
  Future<void> addReview(Review review) {
    final placeRef = _places.doc(review.placeId);
    final reviewRef = placeRef.collection('reviews').doc();
    return _db.runTransaction((tx) async {
      final snap = await tx.get(placeRef);
      if (!snap.exists) {
        throw StateError('المكان مش موجود');
      }
      tx.set(reviewRef, review.toMap());
      tx.update(placeRef, <String, dynamic>{
        'ratingSum': FieldValue.increment(review.rating),
        'ratingCount': FieldValue.increment(1),
      });
    });
  }
}
