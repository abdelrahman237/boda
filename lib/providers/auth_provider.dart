import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../customer/models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _loading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _error = 'User not found';
        _loading = false;
        notifyListeners();
        return false;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      if (data['password'] != password) {
        _error = 'Invalid password';
        _loading = false;
        notifyListeners();
        return false;
      }

      _currentUser = User(
        id: doc.id,
        fullName: data['fullName'] ?? data['fullname'] ?? '',
        email: data['email'] ?? '',
      );

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

  Future<bool> register(String email, String fullName, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _error = 'User already exists';
        _loading = false;
        notifyListeners();
        return false;
      }

      final docRef = await _db.collection('users').add({
        'email': email,
        'fullName': fullName,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newUserDoc = await docRef.get();
      final data = newUserDoc.data()!;

      _currentUser = User(
        id: newUserDoc.id,
        fullName: data['fullName'] ?? data['fullname'] ?? '',
        email: data['email'] ?? '',
      );

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

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}


