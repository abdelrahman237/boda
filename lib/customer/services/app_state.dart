import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/movie.dart';
import '../models/booking.dart';

class AppState {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== Users =====
  
  // Login user
  static Future<User?> loginUser(String email, String password) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      
      // Verify password
      if (data['password'] != password) {
        return null;
      }
      
      return User(
        id: doc.id,
        fullName: data['fullName'] ?? data['fullname'] ?? '',
        email: data['email'] ?? '',
      );
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register new user
  static Future<User?> registerUser(String email, String fullName, String password) async {
    try {
      // Check if user already exists
      final existing = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return null;
      }

      // Create new user
      final docRef = await _db.collection('users').add({
        'email': email,
        'fullName': fullName,
        'password': password, // In production, use Firebase Auth!
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newUserDoc = await docRef.get();
      final data = newUserDoc.data()!;
      
      return User(
        id: newUserDoc.id,
        fullName: data['fullName'] ?? data['fullname'] ?? '',
        email: data['email'] ?? '',
      );
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Get user by ID
  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return User(
        id: doc.id,
        fullName: data['fullName'] ?? data['fullname'] ?? '',
        email: data['email'] ?? '',
      );
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // ===== Movies =====
  
  // Get all movies
  static Future<List<Movie>> getMovies() async {
    try {
      final snapshot = await _db.collection('movies').get();
      print('Firestore returned ${snapshot.docs.length} movie documents'); // Debug
      final movies = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Movie data: ${data['title']} - ${data['posterUrl']}'); // Debug
        // Handle both string and int IDs
        int movieId;
        if (data['id'] != null) {
          movieId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0;
        } else {
          movieId = int.tryParse(doc.id) ?? 0;
        }
        
        return Movie(
          id: movieId,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          posterUrl: data['posterUrl'] ?? '',
          timeSlots: List<String>.from(data['timeSlots'] ?? []),
          totalSeats: data['totalSeats'] ?? 47,
        );
      }).toList();
      print('Returning ${movies.length} movies'); // Debug
      return movies;
    } catch (e) {
      print('Get movies error: $e');
      return [];
    }
  }

  // Get all movies as a real-time stream
  static Stream<List<Movie>> getMoviesStream() {
    return _db.collection('movies').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        int movieId;
        if (data['id'] != null) {
          movieId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0;
        } else {
          movieId = int.tryParse(doc.id) ?? 0;
        }
        
        return Movie(
          id: movieId,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          posterUrl: data['posterUrl'] ?? '',
          timeSlots: List<String>.from(data['timeSlots'] ?? []),
          totalSeats: data['totalSeats'] ?? 47,
        );
      }).toList();
    });
  }

  // ===== Bookings =====
  
  // Get bookings for a specific movie and time slot
  static Future<List<Booking>> getBookings(String movieId, String timeSlot) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('movieId', isEqualTo: movieId)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      return snapshot.docs.map((doc) {
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
    } catch (e) {
      print('Get bookings error: $e');
      return [];
    }
  }

  // Create a new booking
  static Future<void> createBooking(Booking booking) async {
    try {
      // Create the booking
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
        final movieDoc = await _db.collection('movies').where('id', isEqualTo: int.tryParse(booking.movieId) ?? 0).limit(1).get();
        if (movieDoc.docs.isNotEmpty) {
          movieTitle = movieDoc.docs.first.data()['title'] ?? 'Movie';
        }
      } catch (e) {
        print('Error getting movie title: $e');
      }

      // Create notification for vendor
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

      print('Booking and notification created successfully');
    } catch (e) {
      print('Create booking error: $e');
      rethrow;
    }
  }
}
