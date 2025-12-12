import 'package:flutter/material.dart';
import '../models/movie_model.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: movie.imagePath.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  movie.imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 70,
                height: 70,
                color: Colors.grey[300],
                child: const Icon(Icons.movie),
              ),
        title: Text(movie.title),
        subtitle: Text(movie.description),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
