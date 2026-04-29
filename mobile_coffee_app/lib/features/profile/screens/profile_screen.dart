import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Tambahan untuk akses memori
import '../../auth/screens/login_screen.dart';
import '../../../data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  String? nama;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await AuthService.getProfile();

      setState(() {
        nama = data['nama'];
        email = data['email'];
        isLoading = false;
      });
    } catch (e) {
      print("Error profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_kesanController.text.isEmpty || _saranController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kesan dan Saran tidak boleh kosong!")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terima kasih! Kesan & Saran berhasil dikirim."),
      ),
    );
    _kesanController.clear();
    _saranController.clear();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            // 🔥 UBAH JADI ASYNC UNTUK MEMBERSIHKAN MEMORI
            onPressed: () async {
              // 1. Bersihkan semua data lokal (termasuk keranjang dan token login)
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // 2. Cegah error jika pop-up sudah tertutup duluan
              if (!context.mounted) return;

              // 3. Pindah ke layar Login dan hapus riwayat halaman sebelumnya
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
              ),
            ),
            const SizedBox(height: 15),

            isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Text(
                        nama ?? "Nama tidak tersedia",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email ?? "Email tidak tersedia",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

            const Divider(height: 40, thickness: 1),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Kesan & Saran Mata Kuliah TPM",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _kesanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Kesan selama kuliah TPM",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _saranController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Saran untuk mata kuliah ini",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _submitFeedback,
                child: const Text(
                  "Kirim Saran & Kesan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const Divider(height: 40, thickness: 1),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout", style: TextStyle(fontSize: 16)),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}