import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: Jangan lupa sesuaikan import ini ke file login kamu yang sebenarnya
// import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variabel untuk nama & email. Nantinya bisa kamu buat dinamis
  // mengambil dari SharedPreferences hasil login.
  String nama = "Mahasiswa Informatika";
  String email = "mahasiswa@contoh.com";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Kalau kamu menyimpan nama & email saat login, bisa di-load di sini:
    // setState(() {
    //   nama = prefs.getString('nama') ?? nama;
    //   email = prefs.getString('email') ?? email;
    // });
  }

  // 🔥 FITUR POP-UP PREVIEW FOTO PROFIL
  void _showProfilePicturePreview() {
    const String profileUrl =
        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // InteractiveViewer agar foto bisa di-zoom (dicubit)
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(profileUrl, fit: BoxFit.contain),
                ),
              ),
              // Tombol Close (Silang) di pojok kanan atas
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 FITUR POP-UP KONFIRMASI LOGOUT
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Apakah kamu yakin ingin keluar dari aplikasi Cafe App?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // 1. Bersihkan session / token
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;

                // 2. Tutup dialog
                Navigator.pop(context);

                // 3. Arahkan kembali ke halaman Login (Hapus semua history route)
                // TODO: Buka komentar di bawah ini dan arahkan ke LoginScreen kamu
                // Navigator.pushAndRemoveUntil(
                //   context,
                //   MaterialPageRoute(builder: (context) => const LoginScreen()),
                //   (Route<dynamic> route) => false,
                // );

                // Sementara karena belum tahu path loginmu, kita pop sampai awal
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
            // ================= 1. FOTO PROFIL DENGAN POP-UP & IKON KAMERA =================
            GestureDetector(
              onTap: _showProfilePicturePreview,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.brown, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundImage: NetworkImage(
                        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  // Ikon Kamera di pojok kanan bawah foto
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nama,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            // ================= 2. SARAN & KESAN TPM (SYARAT DOSEN) =================
            Card(
              elevation: 4,
              shadowColor: Colors.brown.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.brown[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.feedback_rounded,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            "Saran & Kesan Mata Kuliah TPM",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(thickness: 1),
                    ),
                    const Text(
                      "Kesan:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Mata kuliah Teknologi dan Pemrograman Mobile (TPM) sangat seru dan menantang! Banyak hal praktikal yang dipelajari, mulai dari perancangan UI/UX responsif, integrasi API Node.js, hingga pemanfaatan sensor dan hardware pada Flutter.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(height: 1.4, color: Colors.black54),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Saran:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Semoga kedepannya waktu pengerjaan projek akhir bisa lebih diperpanjang, dan mungkin bisa ditambahkan studi kasus yang lebih mendalam terkait integrasi AI/ML di dalam aplikasi Flutter.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(height: 1.4, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ================= 3. TOMBOL LOGOUT =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  "Logout dari Aplikasi",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _showLogoutDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}