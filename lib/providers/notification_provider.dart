import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = _db
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            _unreadCount = snapshot.docs.length;
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to notifications: $error');
            _unreadCount = 0;
            notifyListeners();
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}


