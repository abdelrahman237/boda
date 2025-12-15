import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/movie_model.dart';

class AddMovieScreen extends StatefulWidget {
  final Movie? movieToEdit;

  const AddMovieScreen({super.key, this.movieToEdit});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  final _timeSlotController = TextEditingController();
  List<String> _timeSlots = [];
  File? _localImage;
  XFile? _webImage; // For web platform support

  bool get isEditMode => widget.movieToEdit != null;

  @override
  void initState() {
    super.initState();
    // Clear any blob URLs from previous sessions
    _webImage = null;
    _localImage = null;
    _imageController.clear();

    if (isEditMode) {
      _titleController.text = widget.movieToEdit!.title;
      _descController.text = widget.movieToEdit!.description;
      // Don't set blob URLs in the controller - only set if it's a valid URL or base64
      final imagePath = widget.movieToEdit!.imagePath;
      if (imagePath.isNotEmpty &&
          !imagePath.startsWith('blob:') &&
          (imagePath.startsWith('http') ||
              imagePath.startsWith('data:image'))) {
        _imageController.text = imagePath;
      }
      _timeSlots = List<String>.from(widget.movieToEdit!.timeSlots);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _timeSlotController.dispose();
    super.dispose();
  }

  void _addTimeSlot() {
    final timeSlot = _timeSlotController.text.trim();
    if (timeSlot.isNotEmpty && !_timeSlots.contains(timeSlot)) {
      setState(() {
        _timeSlots.add(timeSlot);
        _timeSlotController.clear();
      });
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          // On web, immediately read bytes to avoid blob URL issues
          _webImage = pickedFile;
          _imageController.text = ''; // Clear controller, don't use blob URL
          _localImage = null;
          // Read bytes immediately to convert blob to memory (prevents blob URL errors)
          pickedFile
              .readAsBytes()
              .then((bytes) {
                // Bytes are now in memory, blob URL won't be needed
                print('✅ Image bytes loaded: ${bytes.length} bytes');
              })
              .catchError((error) {
                print('❌ Error reading image bytes: $error');
              });
        } else {
          // On mobile, store File
          _localImage = File(pickedFile.path);
          _imageController.text = pickedFile.path;
          _webImage = null;
        }
      });
    }
  }

  // Compress and encode image to base64 string
  Future<String?> _compressAndEncodeImage() async {
    try {
      // If no new image selected and in edit mode, keep existing image
      if (_localImage == null && _webImage == null) {
        if (isEditMode && widget.movieToEdit!.imagePath.isNotEmpty) {
          final existingPath = widget.movieToEdit!.imagePath;
          // Reject blob URLs - they're invalid and cause loading issues
          if (existingPath.startsWith('blob:') || existingPath.length < 100) {
            print(
              '⚠️ Existing image path is invalid (blob URL or too short), ignoring: ${existingPath.substring(0, existingPath.length > 50 ? 50 : existingPath.length)}...',
            );
            return null; // Don't keep invalid blob URLs
          }
          // In edit mode, return the existing image path (URL or base64, but not blob)
          print(
            '📸 Keeping existing image in edit mode: ${existingPath.substring(0, existingPath.length > 50 ? 50 : existingPath.length)}...',
          );
          return existingPath; // Keep existing image (URL or base64)
        }
        return null;
      }

      Uint8List imageBytes;

      if (kIsWeb && _webImage != null) {
        // For web, read bytes from XFile
        print('📤 Processing image from web...');
        imageBytes = await _webImage!.readAsBytes();
      } else if (_localImage != null) {
        // For mobile, read bytes from File
        print('📤 Processing image from mobile: ${_localImage!.path}');
        imageBytes = await _localImage!.readAsBytes();
      } else {
        print('❌ No image to process');
        return null;
      }

      print('📤 Original image size: ${imageBytes.length} bytes');

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to max 800x600 to keep it under 1MB
      int maxWidth = 800;
      int maxHeight = 600;

      if (image.width > maxWidth || image.height > maxHeight) {
        print('📐 Resizing image from ${image.width}x${image.height}...');
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          maintainAspect: true,
        );
        print('📐 Resized to ${image.width}x${image.height}');
      }

      // Compress image (quality 75% - good balance between size and quality)
      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 75),
      );

      print('📤 Compressed image size: ${compressedBytes.length} bytes');

      // Check if still too large (Firestore limit is 1MB)
      if (compressedBytes.length > 900000) {
        // Leave some margin
        print('⚠️ Image still too large, compressing more...');
        // Compress more aggressively
        compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 60));
        print('📤 Re-compressed size: ${compressedBytes.length} bytes');
      }

      // Convert to base64 string
      String base64String = base64Encode(compressedBytes);
      String dataUri = 'data:image/jpeg;base64,$base64String';

      print('✅ Image encoded to base64 (length: ${dataUri.length})');
      return dataUri;
    } catch (e, stackTrace) {
      print('❌ Error processing image: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to build image from base64 or URL
  Widget _buildImageFromData(
    String imageData, {
    double? height,
    double? width,
  }) {
    if (imageData.startsWith('data:image')) {
      // Base64 image
      final base64String = imageData.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    } else if (imageData.startsWith('http') && !imageData.startsWith('blob:')) {
      // URL image (but not blob URLs)
      return Image.network(
        imageData,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    } else {
      // Fallback
      return Container(
        height: height,
        width: width,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade400,
                Color.fromARGB(255, 149, 125, 173),
              ],
            ),
          ),
        ),
        title: Text(isEditMode ? 'Edit Movie' : 'Add New Movie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade400,
                        Color.fromARGB(255, 149, 125, 173),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.movie_creation,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEditMode ? 'Edit Movie Details' : 'Create New Movie',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditMode
                            ? 'Update the details below'
                            : 'Fill in the details below',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Movie Title',
                    hintText: 'Enter movie title',
                    prefixIcon: Icon(
                      Icons.title,
                      color: Colors.indigo.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter a title"
                      : null,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter movie description',
                    prefixIcon: Icon(
                      Icons.description,
                      color: Colors.indigo.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter a description"
                      : null,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _imageController,
                        decoration: InputDecoration(
                          labelText: 'Poster URL or Local Path',
                          prefixIcon: Icon(
                            Icons.image,
                            color: Colors.indigo.shade700,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            118,
                            114,
                            122,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_localImage != null || _webImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && _webImage != null
                            ? FutureBuilder<Uint8List>(
                                future: _webImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      height: 150,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  );
                                },
                              )
                            : _localImage != null
                            ? Image.file(
                                _localImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                      ),
                    // Show existing image if in edit mode and no new image selected
                    if (isEditMode &&
                        widget.movieToEdit!.imagePath.isNotEmpty &&
                        _localImage == null &&
                        _webImage == null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageFromData(
                          widget.movieToEdit!.imagePath,
                          height: 150,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.indigo.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Time Slots',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _timeSlotController,
                              decoration: InputDecoration(
                                hintText: 'e.g., 10:00 AM',
                                prefixIcon: Icon(
                                  Icons.access_time,
                                  color: Colors.indigo.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.indigo.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                              onFieldSubmitted: (_) => _addTimeSlot(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigo.shade400,
                                  Color.fromARGB(255, 149, 125, 173),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _addTimeSlot,
                              icon: const Icon(Icons.add, color: Colors.white),
                              tooltip: 'Add Time Slot',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_timeSlots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No time slots added yet. Add at least one time slot.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(_timeSlots.length, (index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade400,
                                    Color.fromARGB(255, 149, 125, 173),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _timeSlots[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeTimeSlot(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (_timeSlots.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add at least one time slot',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Check if image is selected
                        if (_localImage == null &&
                            _webImage == null &&
                            (!isEditMode ||
                                widget.movieToEdit!.imagePath.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an image'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Show loading dialog and store its context
                        BuildContext? dialogContext;
                        // showDialog(
                        //   context: context,
                        //   barrierDismissible: false,
                        //   builder: (dialogCtx) {
                        //     dialogContext = dialogCtx;
                        //     return const Center(
                        //       child: CircularProgressIndicator(),
                        //     );
                        //   },
                        // );
                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          useRootNavigator: true, // يضمن إنه يغلق من أي مكان
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        // Close the loading dialog later
                        Navigator.of(context, rootNavigator: true).pop();

                        try {
                          print('🔄 Starting update process...');

                          // Compress and encode image to base64
                          print('📸 Processing image...');
                          String? imageData = await _compressAndEncodeImage();
                          print(
                            '📸 Image processing complete. Result: ${imageData != null ? "Success" : "Null"}',
                          );

                          // If encoding failed and not in edit mode (or no existing image), show error
                          if (imageData == null || imageData.isEmpty) {
                            // In edit mode, if no new image selected, we should have kept the existing one
                            // If we get here, it means there's no existing image either
                            if (isEditMode &&
                                widget.movieToEdit!.imagePath.isNotEmpty) {
                              // This shouldn't happen, but use existing image as fallback
                              print(
                                '⚠️ Warning: imageData is null but existing image exists, using existing image',
                              );
                              imageData = widget.movieToEdit!.imagePath;
                            } else {
                              if (dialogContext != null &&
                                  Navigator.canPop(dialogContext!)) {
                                Navigator.pop(
                                  dialogContext!,
                                ); // Close loading dialog
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Error processing image. Please try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              return;
                            }
                          }

                          // Create movie with base64 image data
                          print('🎬 Creating movie object...');
                          final movie = Movie(
                            title: _titleController.text.trim(),
                            description: _descController.text.trim(),
                            imagePath: imageData, // Use base64 encoded image
                            timeSlots: _timeSlots,
                            totalSeats: isEditMode
                                ? widget.movieToEdit!.totalSeats
                                : 47,
                            bookedSeats: isEditMode
                                ? widget.movieToEdit!.bookedSeats
                                : [],
                          );
                          print('🎬 Movie object created: ${movie.title}');
                          print('🎬 Movie timeSlots: ${movie.timeSlots}');
                          print(
                            '🎬 Movie imagePath length: ${movie.imagePath.length}',
                          );

                          // Close loading dialog using dialog context
                          print('✅ Closing loading dialog...');
                          if (dialogContext != null &&
                              Navigator.canPop(dialogContext!)) {
                            Navigator.pop(
                              dialogContext!,
                            ); // Close loading dialog
                          }

                          // Return movie to parent using screen context
                          print('✅ Returning movie to parent: ${movie.title}');
                          print(
                            '✅ Movie object details - Title: ${movie.title}, TimeSlots: ${movie.timeSlots.length}',
                          );

                          if (mounted) {
                            // Use the screen context, not the dialog context
                            Navigator.of(context).pop(movie);
                            print('✅ Movie returned via Navigator.pop()');
                          } else {
                            print('❌ Widget not mounted, cannot return movie');
                          }

                          print('✅ Update process complete!');
                        } catch (e, stackTrace) {
                          print('❌ Error in update process: $e');
                          print('❌ Stack trace: $stackTrace');

                          // Ensure loading dialog is closed
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Close loading dialog
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Details',
                                textColor: Colors.white,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Update Error'),
                                      content: SingleChildScrollView(
                                        child: Text(
                                          '${e.toString()}\n\n$stackTrace',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditMode ? Icons.save : Icons.add_circle_outline,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditMode ? 'Update Movie' : 'Add Movie',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
