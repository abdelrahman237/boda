import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../vendor/models/movie_model.dart';

class VendorMovieProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Map<String, Movie> _movies = {};
  Map<String, String> _movieDocIds = {};
  bool _loading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _moviesSubscription;
  Timer? _debounceTimer;

  Map<String, Movie> get movies => _movies;
  List<Movie> get moviesList => _movies.values.toList();
  Map<String, String> get movieDocIds => _movieDocIds;
  bool get loading => _loading;
  String? get error => _error;

  VendorMovieProvider() {
    _listenToMovies();
  }

  void _listenToMovies() {
    _loading = true;
    notifyListeners();

    _moviesSubscription = _db.collection('movies').snapshots().listen(
      (snapshot) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 250), () {
          final newMovies = <String, Movie>{};
          final newDocIds = <String, String>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            String movieId = '';
            if (data['id'] != null) {
              movieId = data['id'].toString();
            } else {
              movieId = doc.id;
            }

            final movie = Movie(
              id: movieId,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              imagePath: data['posterUrl'] ?? data['imagePath'] ?? '',
              timeSlots: List<String>.from(data['timeSlots'] ?? []),
              totalSeats: data['totalSeats'] ?? 47,
            );

            newMovies[doc.id] = movie;
            newDocIds[movie.title] = doc.id;
          }

          _movies = newMovies;
          _movieDocIds = newDocIds;
          _loading = false;
          _error = null;
          notifyListeners();
        });
      },
      onError: (error) {
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addMovie(Movie movie) async {
    try {
      final movieId = DateTime.now().millisecondsSinceEpoch;
      await _db.collection('movies').add({
        'id': movieId,
        'title': movie.title,
        'description': movie.description,
        'posterUrl': movie.imagePath,
        'timeSlots': movie.timeSlots,
        'totalSeats': movie.totalSeats,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMovie(String docId, Movie movie) async {
    try {
      await _db.collection('movies').doc(docId).update({
        'title': movie.title,
        'description': movie.description,
        'posterUrl': movie.imagePath,
        'timeSlots': movie.timeSlots,
        'totalSeats': movie.totalSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMovie(String docId) async {
    try {
      await _db.collection('movies').doc(docId).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _moviesSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}


