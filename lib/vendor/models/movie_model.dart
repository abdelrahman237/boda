class Movie {
  final String
  id; // سيكون الـ 'id' field من داخل الـ document (ليس document ID)
  final String title;
  final String description;
  final String imagePath;
  final List<String> timeSlots;
  final int totalSeats;
  final List<int> bookedSeats;

  Movie({
    this.id = '',
    required this.title,
    required this.description,
    required this.imagePath,
    required this.timeSlots,
    this.totalSeats = 47,
    this.bookedSeats = const [],
  });

  // Create Movie from Firebase document
  factory Movie.fromFirestore(Map<String, dynamic> data, String docId) {
    // استخدم الـ 'id' field من داخل الـ document (نفس اللي الـ Customer بيستخدمه)
    String movieId = '';
    if (data['id'] != null) {
      movieId = data['id'].toString(); // تحويل لـ String سواء كان int أو String
    } else {
      movieId = docId; // fallback للـ document ID
    }

    return Movie(
      id: movieId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imagePath: data['posterUrl'] ?? data['imagePath'] ?? '',
      timeSlots: List<String>.from(data['timeSlots'] ?? []),
      totalSeats: data['totalSeats'] ?? 47,
      bookedSeats: data['bookedSeats'] != null
          ? List<int>.from(data['bookedSeats'])
          : [],
    );
  }

  // Convert Movie to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': imagePath,
      'timeSlots': timeSlots,
      'totalSeats': totalSeats,
    };
  }

  // Create a copy with modified fields
  Movie copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    List<String>? timeSlots,
    int? totalSeats,
    List<int>? bookedSeats,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      timeSlots: timeSlots ?? this.timeSlots,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
    );
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, description: $description, imagePath: $imagePath, timeSlots: $timeSlots, totalSeats: $totalSeats)';
  }
}
