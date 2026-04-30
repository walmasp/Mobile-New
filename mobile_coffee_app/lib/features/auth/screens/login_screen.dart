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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final LocalAuthentication auth = LocalAuthentication();
  bool canCheckBiometrics = false;
  List<BiometricType> availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    checkBiometrics();
  }

  Future<void> checkBiometrics() async {
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        availableBiometrics = await auth.getAvailableBiometrics();
        if (mounted) setState(() {});
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

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // 🔥 PERBAIKAN: Simpan Token, Nama, dan Email dari Database ke SharedPreferences
        await prefs.setString('token', responseData['token']);

        // Pastikan struktur JSON dari backendmu mengandung field 'user'
        if (responseData['user'] != null) {
          await prefs.setString(
            'user_name',
            responseData['user']['nama'] ?? "User",
          );
          await prefs.setString(
            'user_email',
            responseData['user']['email'] ?? _emailController.text,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Login Berhasil!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Gagal Login")),
        );
      }
    } catch (e) {
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

  Future<void> _handleBiometricLogin() async {
    try {
      String reason = availableBiometrics.contains(BiometricType.face)
          ? 'Gunakan Face ID untuk masuk ke Cafe App'
          : 'Gunakan sidik jari untuk masuk ke Cafe App';

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

              if (canCheckBiometrics) ...[
                const SizedBox(height: 10),
                const Text("Atau masuk dengan"),
                IconButton(
                  icon: Icon(
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
