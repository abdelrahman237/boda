import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../../providers/vendor_movie_provider.dart';
import '../../providers/notification_provider.dart';
import 'add_movie_screen.dart';
import 'movie_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _shownNotificationIds = {}; // Track shown notifications

  @override
  void initState() {
    super.initState();
    // Listen to notifications for showing snackbars
    _listenToNotifications();
  }

  void _listenToNotifications() {
    // Listen to notifications for showing snackbars when new bookings arrive
    FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            // Show notification for new bookings (only show newly added ones)
            if (snapshot.docChanges.isNotEmpty) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added &&
                    change.doc.exists &&
                    !_shownNotificationIds.contains(change.doc.id)) {
                  final notification = {
                    'id': change.doc.id,
                    ...change.doc.data() as Map<String, dynamic>,
                  };
                  _shownNotificationIds.add(change.doc.id);
                  if (mounted) {
                    _showBookingNotification(notification);
                  }
                }
              }
            }
          },
          onError: (error) {
            print('⚠️ Error listening to notifications: $error');
          },
        );
  }

  void _showBookingNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification['title'] ?? 'New Booking',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'ok',
          textColor: Colors.white,
          onPressed: () {
            _markNotificationAsRead(notification);
          },
        ),
      ),
    );
  }

  Future<void> _markNotificationAsRead(
    Map<String, dynamic> notification,
  ) async {
    try {
      final notificationId = notification['id'] ?? '';
      if (notificationId.isNotEmpty) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.markAsRead(notificationId);
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.markAllAsRead();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _showNotificationsDialog() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();

      if (!mounted) return;

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.indigo.shade700),
              SizedBox(width: 8),
              Text('Notifications'),
              if (notificationProvider.unreadCount > 0)
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notificationProvider.unreadCount}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['read'] ?? false;
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.grey.shade100
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isRead
                                ? Colors.grey.shade300
                                : Colors.blue.shade200,
                            width: isRead ? 1 : 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_seat,
                                  size: 16,
                                  color: Colors.indigo.shade700,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? 'Notification',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (notification['createdAt'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  _formatTimestamp(notification['createdAt']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                if (notificationProvider.unreadCount > 0) {
                  return TextButton(
                    onPressed: () {
                      _markAllNotificationsAsRead();
                      Navigator.pop(context);
                    },
                    child: Text('Mark all as read'),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing notifications: $e');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(92, 107, 192, 1),
                Color.fromARGB(255, 149, 125, 173),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Align(
          alignment: Alignment.centerLeft, // كلمة Vendor تبدا من الشمال
          child: Text(
            "Vendor App",
            style: TextStyle(
              color: Color.fromARGB(255, 235, 234, 234), // النص أبيض
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 235, 234, 234), // أيقونات أبيض
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotificationsDialog,
                tooltip: 'Notifications',
              ),
                  if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                          notificationProvider.unreadCount > 9 
                              ? '9+' 
                              : '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: Consumer<VendorMovieProvider>(
        builder: (context, vendorProvider, child) {
          if (vendorProvider.loading && vendorProvider.moviesList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RepaintBoundary(
              child: ListView.builder(
                key: const PageStorageKey<String>('movies_list'),
                padding: const EdgeInsets.all(16),
              itemCount: vendorProvider.moviesList.length,
              cacheExtent: 1000,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
                itemBuilder: (context, index) {
                final movie = vendorProvider.moviesList[index];
                  return RepaintBoundary(
                    key: ValueKey('movie_${movie.title}'),
                  child: _buildMovieCard(movie, index, vendorProvider),
                  );
                },
              ),
          );
        },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newMovie = await Navigator.push<Movie?>(
            context,
            MaterialPageRoute(builder: (_) => const AddMovieScreen()),
          );
          if (newMovie != null) {
            final vendorProvider = Provider.of<VendorMovieProvider>(context, listen: false);
            final success = await vendorProvider.addMovie(newMovie);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                  content: Text(success 
                      ? 'Movie added successfully!' 
                      : 'Error: ${vendorProvider.error}'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, int index, VendorMovieProvider vendorProvider) {
    // Use movie title + index as key to maintain widget identity during updates
    return Container(
      key: ValueKey('movie_${movie.title}_$index'),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(movie: movie),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large Movie Poster
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      if (movie.imagePath.isNotEmpty)
                        _buildMovieImage(movie.imagePath, 250)
                      else
                        Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.indigo.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      // Action buttons overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final docId = vendorProvider.movieDocIds[movie.title];
                                  if (docId != null) {
                                    final updatedMovie = await Navigator.push<Movie?>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddMovieScreen(
                                              movieToEdit: movie,
                                            ),
                                          ),
                                        );
                                    if (updatedMovie != null) {
                                      final success = await vendorProvider.updateMovie(docId, updatedMovie);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                            content: Text(success 
                                                ? 'Movie updated successfully!' 
                                                : 'Error: ${vendorProvider.error}'),
                                            backgroundColor: success ? Colors.green : Colors.red,
                                            duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                    }
                                  }
                                },
                                tooltip: 'Edit Movie',
                              ),
                            ),
                            // Delete button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Movie'),
                                      content: Text(
                                        'Are you sure you want to delete "${movie.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    final docId = vendorProvider.movieDocIds[movie.title];
                                      if (docId != null) {
                                      final success = await vendorProvider.deleteMovie(docId);
                                        if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success 
                                                ? 'Movie deleted successfully!' 
                                                : 'Error: ${vendorProvider.error}'),
                                            backgroundColor: success ? Colors.green : Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                tooltip: 'Delete Movie',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Movie Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color.fromRGBO(92, 107, 192, 1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.timeSlots.length} time slots',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.event_seat,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.totalSeats} seats',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cache for decoded images to prevent re-decoding on every rebuild
  // Static cache persists across rebuilds and widget recreations
  static final Map<String, Uint8List> _imageCache = {};
  
  // Cache for decode futures to prevent recreating FutureBuilder
  static final Map<String, Future<Uint8List>> _decodeFutures = {};
  
  Future<Uint8List> _decodeBase64ImageAsync(String imageData) async {
    // Check if we already have a future for this image
    if (_decodeFutures.containsKey(imageData)) {
      return _decodeFutures[imageData]!;
    }
    
    // Create new future
    final future = Future<Uint8List>.microtask(() {
      try {
        String base64String;
        if (imageData.startsWith('data:image')) {
          base64String = imageData.split(',')[1];
        } else {
          base64String = imageData;
        }
        
        final bytes = base64Decode(base64String);
        _imageCache[imageData] = bytes; // Cache the result
        _decodeFutures.remove(imageData); // Remove future once done
        return bytes;
      } catch (e) {
        _decodeFutures.remove(imageData);
        throw Exception('Failed to decode base64 image: $e');
      }
    });
    
    _decodeFutures[imageData] = future;
    return future;
  }

  // Helper method to build image from base64 or URL
  Widget _buildMovieImage(String imageData, double height) {
    // Check for base64 image (with or without data:image prefix)
    if (imageData.startsWith('data:image') || (imageData.length > 500 && !imageData.startsWith('http'))) {
      // Base64 image - check cache FIRST, then decode synchronously like customer screens
      Uint8List? cachedBytes = _imageCache[imageData];
      
      if (cachedBytes != null) {
        // Use cached image - instant display, no loading spinner
        return Image.memory(
          cachedBytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            _imageCache.remove(imageData);
            return _buildErrorImage(height);
          },
        );
      }
      
      // Not in cache - decode in isolate to prevent blocking UI thread
      // Use FutureBuilder but cache the future to prevent recreation
      return FutureBuilder<Uint8List>(
        future: _decodeBase64ImageAsync(imageData),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show placeholder while decoding - don't show spinner to avoid freeze feeling
            return Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.white,
                size: 40,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorImage(height);
          }
          
          return Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              _imageCache.remove(imageData);
              return _buildErrorImage(height);
            },
          );
        },
      );
    } else if (imageData.startsWith('blob:')) {
      return _buildErrorImage(height);
    } else if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageData,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade400,
                Colors.purple.shade400,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorImage(height),
      );
    } else {
      return _buildErrorImage(height);
    }
  }

  Widget _buildErrorImage(double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade400,
            Colors.purple.shade400,
          ],
        ),
      ),
      child: const Icon(
        Icons.movie,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}
