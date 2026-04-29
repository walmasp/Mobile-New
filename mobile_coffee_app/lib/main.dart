import 'package:flutter/material.dart';
// Import halaman Login sebagai pintu masuk utama
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafe Aggregator',
      theme: ThemeData(
        // Kita set tema utama ke warna Cokelat (Brown) agar sesuai tema Cafe
        primarySwatch: Colors.brown,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      // Halaman pertama yang muncul adalah LoginScreen
      home: const LoginScreen(),
    );
  }
}
