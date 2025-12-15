// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import '../firebase_options.dart';
// import 'screens/home_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     runApp(const VendorApp());
//   } catch (e) {
//     runApp(ErrorApp(error: e.toString()));
//   }
// }

// class VendorApp extends StatelessWidget {
//   const VendorApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "Cinema Vendor Dashboard",
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.indigo,
//           brightness: Brightness.light,
//         ),
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: true,
//           titleTextStyle: const TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.5,
//           ),
//           iconTheme: const IconThemeData(color: Colors.white),
//         ),
//         cardTheme: CardThemeData(
//           elevation: 8,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: Colors.white.withOpacity(0.95),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
//           ),
//           labelStyle: TextStyle(color: Colors.grey.shade700),
//           hintStyle: TextStyle(color: Colors.grey.shade500),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.indigo.shade700,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             textStyle: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             elevation: 4,
//           ),
//         ),
//         floatingActionButtonTheme: FloatingActionButtonThemeData(
//           backgroundColor: Colors.indigo.shade700,
//           foregroundColor: Colors.white,
//           elevation: 8,
//         ),
//       ),
//       home: const HomeScreen(),
//     );
//   }
// }

// class ErrorApp extends StatelessWidget {
//   final String error;
//   const ErrorApp({super.key, required this.error});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Text('Error initializing Firebase: $error'),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';
import 'screens/home_screen.dart';
import '../providers/vendor_movie_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/booking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const VendorApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VendorMovieProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Cinema Vendor Dashboard",
        theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error initializing Firebase: $error')),
      ),
    );
  }
}
