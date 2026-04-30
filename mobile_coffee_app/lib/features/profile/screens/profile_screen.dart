import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // 🔥 IMPORT IMAGE PICKER
// TODO: Pastikan import ini mengarah ke file LoginScreen kamu
// import '../../features/auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nama = "Memuat...";
  String _email = "Memuat...";
  String _kesanPesan = "Memuat...";
  String? _imagePath; // 🔥 Variabel untuk menyimpan path foto lokal

  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // Instansiasi Image Picker

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // MENGAMBIL DATA DARI SHAREDPREFERENCES
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nama = prefs.getString('user_name') ?? "Guest User";
      _email = prefs.getString('user_email') ?? "guest@cafe.com";
      _kesanPesan =
          prefs.getString('user_bio') ??
          "Halo! Saya sangat suka kopi dan tempat estetik.";
      _imagePath = prefs.getString('user_image'); // Ambil path foto jika ada
    });
  }

  // 🔥 FUNGSI MEMILIH FOTO DARI GALERI
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Buka Galeri
        imageQuality: 50, // Kompres sedikit agar tidak berat
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_image',
          pickedFile.path,
        ); // Simpan path foto
        setState(() {
          _imagePath = pickedFile.path; // Perbarui tampilan UI
        });
      }
    } catch (e) {
      print("Gagal mengambil foto: $e");
    }
  }

  // FUNGSI UNTUK MENYIMPAN KESAN & PESAN BARU
  Future<void> _saveKesanPesan(String newBio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_bio', newBio);
    setState(() {
      _kesanPesan = newBio;
    });
  }

  // POP-UP UNTUK EDIT KESAN & PESAN
  void _showEditBioDialog() {
    _bioController.text = _kesanPesan;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Edit Kesan & Pesan",
          style: TextStyle(color: Colors.brown),
        ),
        content: TextField(
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Tulis kesan & pesanmu di sini...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.brown, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () {
              _saveKesanPesan(_bioController.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // FUNGSI LOGOUT
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Konfirmasi Logout",
          style: TextStyle(color: Colors.brown),
        ),
        content: const Text("Apakah kamu yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!mounted) return;
              // Navigator.pushAndRemoveUntil(
              //   context,
              //   MaterialPageRoute(builder: (context) => const LoginScreen()),
              //   (route) => false,
              // );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.white),
            ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔥 TAMPILAN FOTO PROFIL (BISA DIKLIK)
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.brown,
                    // Jika _imagePath ada isinya, tampilkan foto. Jika tidak, tampilkan ikon default
                    backgroundImage: _imagePath != null
                        ? FileImage(File(_imagePath!))
                        : null,
                    child: _imagePath == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                // Ikon kamera kecil di pojok foto profil
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.brown[800],
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              _nama,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            // Kartu Kesan Pesan
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.format_quote, color: Colors.brown),
                            SizedBox(width: 10),
                            Text(
                              "Kesan & Pesan",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.brown,
                            size: 20,
                          ),
                          onPressed: _showEditBioDialog,
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      _kesanPesan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
