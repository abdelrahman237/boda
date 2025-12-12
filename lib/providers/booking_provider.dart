import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../customer/models/booking.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Booking> _currentBookings = [];
  bool _loading = false;
  String? _error;

  List<Booking> get currentBookings => _currentBookings;
  bool get loading => _loading;
  String? get error => _error;

  Future<List<Booking>> getBookings(String movieId, String timeSlot) async {
    _loading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('bookings')
          .where('movieId', isEqualTo: movieId)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      _currentBookings = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime dateTime;
        if (data['dateTime'] is Timestamp) {
          dateTime = (data['dateTime'] as Timestamp).toDate();
        } else if (data['dateTime'] is String) {
          dateTime = DateTime.parse(data['dateTime']);
        } else {
          dateTime = DateTime.now();
        }

        return Booking(
          id: doc.id,
          userEmail: data['userEmail'] ?? '',
          movieId: data['movieId'] ?? '',
          seats: List<String>.from(data['seats'] ?? []),
          dateTime: dateTime,
          timeSlot: data['timeSlot'] ?? timeSlot,
        );
      }).toList();

      _loading = false;
      _error = null;
      notifyListeners();
      return _currentBookings;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return [];
    }
  }

  Future<bool> createBooking(Booking booking) async {
    _loading = true;
    notifyListeners();

    try {
      final bookingRef = await _db.collection('bookings').add({
        'userEmail': booking.userEmail,
        'movieId': booking.movieId,
        'seats': booking.seats,
        'timeSlot': booking.timeSlot,
        'dateTime': Timestamp.fromDate(booking.dateTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get movie title for notification
      String movieTitle = 'Movie';
      try {
        final movieDoc = await _db
            .collection('movies')
            .where('id', isEqualTo: int.tryParse(booking.movieId) ?? 0)
            .limit(1)
            .get();
        if (movieDoc.docs.isNotEmpty) {
          movieTitle = movieDoc.docs.first.data()['title'] ?? 'Movie';
        }
      } catch (e) {
        print('Error getting movie title: $e');
      }

      // Create notification
      await _db.collection('notifications').add({
        'type': 'booking',
        'title': 'New Booking',
        'message': '${booking.userEmail} booked ${booking.seats.length} seat(s) for "$movieTitle" at ${booking.timeSlot}',
        'bookingId': bookingRef.id,
        'movieId': booking.movieId,
        'movieTitle': movieTitle,
        'userEmail': booking.userEmail,
        'seats': booking.seats,
        'timeSlot': booking.timeSlot,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _loading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}


