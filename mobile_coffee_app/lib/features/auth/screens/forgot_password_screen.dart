import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleResetRequest() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan email kamu terlebih dahulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sesuaikan endpoint ini dengan backend MySQL kamu (misal: /auth/forgot-password)
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": _emailController.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Email tidak ditemukan")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan koneksi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Email Terkirim"),
        content: const Text(
          "Silakan cek kotak masuk email kamu untuk instruksi reset password.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman Login
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        title: const Text("Reset Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.brown),
            const SizedBox(height: 20),
            const Text(
              "Lupa Password?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Masukkan email yang terdaftar, kami akan mengirimkan link untuk mengatur ulang password kamu.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email Pemulihan",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.brown)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _handleResetRequest,
                    child: const Text(
                      "KIRIM INSTRUKSI",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
