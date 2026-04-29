import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../../core/config/api_config.dart'; // Import ini sudah benar sesuai struktur foldermu

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _enableBiometric = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // 1. Validasi Input
    if (_namaController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Semua kolom wajib diisi!");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Password dan Konfirmasi tidak cocok!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Kirim data ke API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nama": _namaController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "role": "pelanggan",
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Berhasil simpan ke database
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('use_biometric', _enableBiometric);
        
        _showSnackBar(responseData['message'] ?? "Registrasi Berhasil!");

        // Pindah ke halaman Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Gagal (Misal email sudah terdaftar)
        _showSnackBar(responseData['message'] ?? "Gagal Registrasi");
      }
    } catch (e) {
      // Tampilkan error ke terminal untuk debugging
      print("DETAIL ERROR REGISTER: $e"); 
      if (!mounted) return;
      _showSnackBar("Tidak dapat terhubung ke server. Cek koneksi & IP!");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // UI tetap sama dengan yang kamu buat
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1, size: 80, color: Colors.brown),
              const SizedBox(height: 20),
              const Text("Daftar Akun", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
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
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text("Aktifkan Login Sidik Jari"),
                value: _enableBiometric,
                activeThumbColor: Colors.brown,
                onChanged: (bool value) => setState(() => _enableBiometric = value),
              ),
              const SizedBox(height: 20),
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.brown)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.brown),
                    onPressed: _handleRegister,
                    child: const Text("DAFTAR", style: TextStyle(color: Colors.white)),
                  ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("Sudah punya akun? Login di sini", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}