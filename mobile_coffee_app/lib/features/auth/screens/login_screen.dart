import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http; // Untuk tembak API
import 'dart:convert'; // Untuk handle JSON
import 'package:shared_preferences/shared_preferences.dart'; // Untuk simpan token/sesi

import '../../../shared/layout/main_navigation_screen.dart';
import 'register_screen.dart';
import '../../../core/config/api_config.dart'; // Pastikan path ini benar sesuai struktur foldermu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Controller untuk menangkap teks yang diketik user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false; // Indikator loading

  // 🔥 VARIABEL BIOMETRIK DITAMBAHKAN DI SINI
  final LocalAuthentication auth = LocalAuthentication();
  bool canCheckBiometrics = false;
  List<BiometricType> availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    checkBiometrics(); // 🔥 Panggil pengecekan sensor saat layar dibuka
  }

  // 🔥 FUNGSI CEK SENSOR HP (Face ID atau Sidik Jari)
  Future<void> checkBiometrics() async {
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        availableBiometrics = await auth.getAvailableBiometrics();
        if (mounted) setState(() {}); // Update tampilan layar
      }
    } catch (e) {
      print("Error cek biometrik: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI LOGIN KE BACKEND ---
  Future<void> _handleLogin() async {
    // Validasi input kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Tembak API Login dengan timeout 10 detik
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "email": _emailController.text,
              "password": _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      // Status 200 berarti sukses (sesuai authController.js)
      if (response.statusCode == 200) {
        // 3. Simpan Token JWT ke memori HP agar tidak perlu login terus
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Login Berhasil!")),
        );

        // 4. Pindah ke Halaman Utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        // Gagal login (misal salah password atau email tidak ada)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Gagal Login")),
        );
      }
    } catch (e) {
      // Error karena masalah jaringan/koneksi
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Tidak dapat terhubung ke server ($e)")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi Login Biometrik (Kembali ke versi aslimu yang sukses)
  Future<void> _handleBiometricLogin() async {
    try {
      // Teks menyesuaikan apakah HP punya Face ID atau Sidik Jari
      String reason = availableBiometrics.contains(BiometricType.face)
          ? 'Gunakan Face ID untuk masuk ke Cafe App'
          : 'Gunakan sidik jari untuk masuk ke Cafe App';

      // 🔥 KITA GUNAKAN FORMAT ASLIMU YANG SUDAH TERBUKTI JALAN KEMARIN
      bool authenticated = await auth.authenticate(localizedReason: reason);

      if (authenticated) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      print("Error Biometrik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_cafe, size: 100, color: Colors.brown),
              const SizedBox(height: 20),
              const Text(
                "Cafe Agregator",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // TextField Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              // TextField Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Tombol Login dengan Indikator Loading
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.brown)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.brown,
                      ),
                      onPressed: _handleLogin,
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

              const SizedBox(height: 15),

              // Tombol untuk pindah ke halaman Register
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Belum punya akun? Daftar di sini",
                  style: TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 🔥 LOGIKA TAMPILAN IKON BIOMETRIK DINAMIS (Muncul jika HP mendukung)
              if (canCheckBiometrics) ...[
                const SizedBox(height: 10),
                const Text("Atau masuk dengan"),
                IconButton(
                  icon: Icon(
                    // Cek apakah ada Face ID, jika tidak gunakan icon sidik jari
                    availableBiometrics.contains(BiometricType.face)
                        ? Icons.face
                        : Icons.fingerprint,
                    size: 50,
                    color: Colors.brown,
                  ),
                  onPressed: _handleBiometricLogin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}