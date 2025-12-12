import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';



class VendorServices {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب كل الحجوزات الخاصة بفيلم ووقت محدد
  static Future<List<Booking>> getBookingsForVendor(String movieId, String timeSlot) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('movieId', isEqualTo: movieId)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Booking(
          id: doc.id,
          userEmail: data['userEmail'] ?? '',
          movieId: data['movieId'] ?? '',
          seats: List<String>.from(data['seats'] ?? []),
          dateTime: (data['dateTime'] as Timestamp).toDate(),
          timeSlot: data['timeSlot'] ?? timeSlot,
        );
      }).toList();
    } catch (e) {
      print('Get bookings error for vendor: $e');
      return [];
    }
  }
}
