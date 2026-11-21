import '../models/place.dart';
import '../models/review.dart';

/// واجهة البيانات. فيها تنفيذين:
/// - [DemoPlacesRepository]: بيانات تجريبية جوه الجهاز.
/// - [FirestorePlacesRepository]: بيانات حقيقية على Firebase.
abstract class PlacesRepository {
  /// الأماكن المتوافق عليها (اللي بتظهر للناس).
  Stream<List<Place>> watchApproved();

  /// الأماكن اللي مستنية مراجعة الأدمن.
  Stream<List<Place>> watchPending();

  /// تقييمات مكان معين (الأحدث الأول).
  Stream<List<Review>> watchReviews(String placeId);

  /// صاحب مكان بيضيف مكانه، فيتسجل "قيد المراجعة".
  Future<void> submitPlace(Place place);

  /// الأدمن بيوافق أو يرفض.
  Future<void> setStatus(String placeId, PlaceStatus status);

  /// إضافة تقييم وتحديث متوسط تقييم المكان.
  Future<void> addReview(Review review);
}
