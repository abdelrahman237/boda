import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'role_selector.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/vendor_movie_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Continue anyway - app will show error if needed
  }
  runApp(const CinemaBookingApp());
}

class CinemaBookingApp extends StatelessWidget {
  const CinemaBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => VendorMovieProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Cinema Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
        home: const RoleSelector(),
      ),
    );
  }
}
