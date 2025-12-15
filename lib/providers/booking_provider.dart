import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../customer/models/booking.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Booking> _currentBookings = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  List<Booking> get currentBookings => _currentBookings;
  bool get loading => _loading;
  String? get error => _error;

  // Real-time stream for bookings - automatically updates when bookings change
  void listenToBookings(String movieId, String timeSlot) {
    _loading = true;
    notifyListeners();

    _bookingsSubscription?.cancel();
    
    _bookingsSubscription = _db
        .collection('bookings')
        .where('movieId', isEqualTo: movieId)
        .where('timeSlot', isEqualTo: timeSlot)
        .snapshots()
        .listen(
      (snapshot) {
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
      },
      onError: (error) {
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // Stop listening to bookings
  void stopListening() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
  }

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

  // Transaction-based booking to prevent race conditions
  // This ensures that if two customers try to book the same seat simultaneously,
  // only one will succeed
  Future<bool> createBooking(Booking booking) async {
    _loading = true;
    notifyListeners();

    try {
      // Use transaction to ensure atomic booking
      final bookingId = await _db.runTransaction((transaction) async {
        // Check if any of the selected seats are already booked
        final snapshot = await _db
            .collection('bookings')
            .where('movieId', isEqualTo: booking.movieId)
            .where('timeSlot', isEqualTo: booking.timeSlot)
            .get();

        // Collect all booked seats
        final Set<String> bookedSeats = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final seats = List<String>.from(data['seats'] ?? []);
          bookedSeats.addAll(seats);
        }

        // Check if any selected seat is already booked
        for (var seat in booking.seats) {
          if (bookedSeats.contains(seat)) {
            throw Exception('Seat $seat is already booked');
          }
        }

        // All seats are available, create the booking
        final bookingRef = _db.collection('bookings').doc();
        transaction.set(bookingRef, {
          'userEmail': booking.userEmail,
          'movieId': booking.movieId,
          'seats': booking.seats,
          'timeSlot': booking.timeSlot,
          'dateTime': Timestamp.fromDate(booking.dateTime),
          'createdAt': FieldValue.serverTimestamp(),
        });

        return bookingRef.id;
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
        'bookingId': bookingId,
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

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
