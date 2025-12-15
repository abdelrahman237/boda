import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../customer/models/movie.dart';

class MovieProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Movie> _movies = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _moviesSubscription;

  List<Movie> get movies => _movies;
  bool get loading => _loading;
  String? get error => _error;

  MovieProvider() {
    _listenToMovies();
  }

  void _listenToMovies() {
    _loading = true;
    notifyListeners();

    _moviesSubscription = _db.collection('movies').snapshots().listen(
      (snapshot) {
        _movies = snapshot.docs.map((doc) {
          final data = doc.data();
          int movieId;
          if (data['id'] != null) {
            movieId = data['id'] is int 
                ? data['id'] 
                : int.tryParse(data['id']?.toString() ?? '0') ?? 0;
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

  @override
  void dispose() {
    _moviesSubscription?.cancel();
    super.dispose();
  }
}


