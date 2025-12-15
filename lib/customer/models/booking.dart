import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userEmail;
  final String movieId;
  final List<String> seats;
  final DateTime dateTime;
  final String timeSlot;

  Booking({
    required this.id,
    required this.userEmail,
    required this.movieId,
    required this.seats,
    required this.dateTime,
    required this.timeSlot,
  });

  // تحويل الحجز لـ Map قبل حفظه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'movieId': movieId,
      'seats': seats,
      'timeSlot': timeSlot,
      'dateTime': Timestamp.fromDate(dateTime), // <--- مهم
    };
  }

  // تحويل بيانات Firestore لـ Booking
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      movieId: map['movieId'] ?? '',
      seats: List<String>.from(map['seats'] ?? []),
      timeSlot: map['timeSlot'] ?? '',
      dateTime: map['dateTime'] is Timestamp
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}
