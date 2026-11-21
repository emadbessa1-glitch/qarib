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

  /// أماكن صاحب عمل معين (بكل حالاتها).
  Stream<List<Place>> watchMine(String ownerId);

  /// صاحب المكان بيفعّل الواتساب (برقم) أو يقفله (نص فاضي = الشات جوه التطبيق).
  Future<void> updateWhatsapp(String placeId, String whatsapp);

  /// الإدارة (أدمن أو مدير) بتعدّل بيانات المكان. التقييمات والحالة وصاحب المكان مش بيتغيروا.
  Future<void> updatePlace(Place place);

  /// صاحب المكان (لما يمسح حسابه) أو الأدمن.
  Future<void> deletePlace(String placeId);
}
