import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../providers/auth_provider.dart';
import 'movie_details_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A148C), // purple.shade800
                  // Color(0xFF1A237E), // indigo.shade900
                  Color(0xFF0D47A1), // blue.shade900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          title: const Text(
            "Customer App",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: () {
                // Stream automatically updates
                setState(() {});
              },
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.white,
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          // Movies List with Consumer
          Expanded(
            child: Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                if (movieProvider.loading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading movies...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                if (movieProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${movieProvider.error}'),
                      ],
                    ),
                  );
                }

                if (movieProvider.movies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.movie_outlined,
                              size: 64,
                              color: Colors.purple.shade300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No movies available',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new releases',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredMovies = _searchQuery.isEmpty
                    ? movieProvider.movies
                    : movieProvider.movies.where((m) =>
                        m.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filteredMovies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.purple.shade300,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No movies found',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Provider automatically updates
                    setState(() {});
                  },
                  color: Colors.purple.shade600,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      return _buildModernMovieCard(movie, index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMovieCard(Movie movie, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                builder: (context) =>
                    MovieDetailsScreen(user: widget.user, movie: movie),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: movie.posterUrl.isNotEmpty
                    ? _buildMovieImage(movie.posterUrl, 240)
                    : Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.indigo.shade300,
                              Colors.purple.shade300,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white70,
                          size: 60,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${movie.timeSlots.length} slots',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.event_seat,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${movie.totalSeats} seats',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
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
    );
  }

  // Helper method to build image from base64 or URL
  Widget _buildMovieImage(String imageData, double height) {
    if (imageData.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = imageData.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage(height);
          },
        );
      } catch (e) {
        print('❌ Error decoding base64 image: $e');
        return _buildErrorImage(height);
      }
    } else if (imageData.startsWith('http') && !imageData.startsWith('blob:')) {
      // URL image (for backward compatibility) - but not blob URLs
      return CachedNetworkImage(
        imageUrl: imageData,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade300,
                Colors.purple.shade300,
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
      // Fallback
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
            Colors.indigo.shade300,
            Colors.purple.shade300,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }
}
