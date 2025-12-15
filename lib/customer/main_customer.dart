// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import '../firebase_options.dart';
// import 'screens/login_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const CinemaBookingApp());
// }

// class CinemaBookingApp extends StatelessWidget {
//   const CinemaBookingApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Cinema Booking',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.purple,
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.purple,
//           brightness: Brightness.light,
//         ),
//         cardTheme: CardThemeData(
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.shade300),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.shade300),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//         ),
//       ),
//       home: const LoginScreen(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';
import 'screens/login_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../providers/booking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CinemaBookingApp());
}

class CinemaBookingApp extends StatelessWidget {
  const CinemaBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
      ],
      child: MaterialApp(
        title: 'Cinema Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
        home: const LoginScreen(),
      ),
    );
  }
}
