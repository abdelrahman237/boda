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

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userEmail: map['userEmail'] ?? '',
      movieId: map['movieId'] ?? '',
      seats: List<String>.from(map['seats'] ?? []),
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as dynamic).toDate()
          : DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'movieId': movieId,
      'seats': seats,
      'dateTime': dateTime,
      'timeSlot': timeSlot,
    };
  }

  Booking copyWith({
    String? id,
    String? userEmail,
    String? movieId,
    List<String>? seats,
    DateTime? dateTime,
    String? timeSlot,
  }) {
    return Booking(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      movieId: movieId ?? this.movieId,
      seats: seats ?? this.seats,
      dateTime: dateTime ?? this.dateTime,
      timeSlot: timeSlot ?? this.timeSlot,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, userEmail: $userEmail, movieId: $movieId, seats: $seats, dateTime: $dateTime, timeSlot: $timeSlot)';
  }
}
