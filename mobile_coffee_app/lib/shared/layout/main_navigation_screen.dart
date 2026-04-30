import 'package:flutter/material.dart';
// Hapus import barista balance karena sudah tidak dipanggil langsung dari navbar
// import '../../features/mini_games/screens/barista_balance_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../data/services/cafe_service.dart';
import '../../features/menu/screens/menu_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// 🔥 Pastikan import ini mengarah ke lokasi file GamesMenuScreen yang benar
import '../../features/mini_games/screens/games_menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 🔥 PERBAIKAN: Ubah index ke-2 menjadi GamesMenuScreen
  final List<Widget> _pages = [
    const CafeHomeScreen(),
    const CafeMapsScreen(),
    const GamesMenuScreen(), // Ini sudah benar mengarah ke Lobi Games
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Cafe'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Games',
          ), // Ikon yang lebih cocok
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ================= CAFE HOME =================

class CafeHomeScreen extends StatefulWidget {
  const CafeHomeScreen({super.key});

  @override
  State<CafeHomeScreen> createState() => _CafeHomeScreenState();
}

class _CafeHomeScreenState extends State<CafeHomeScreen> {
  List cafes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCafes();
  }

  Future<void> fetchCafes() async {
    try {
      final data = await CafeService.getCafes();

      setState(() {
        cafes = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error cafe: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Cafe"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        // 🔥 TAMBAHAN ICON LONCENG NOTIFIKASI
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cafes.isEmpty
          ? const Center(child: Text("Tidak ada cafe"))
          : ListView.builder(
              itemCount: cafes.length,
              itemBuilder: (context, index) {
                final cafe = cafes[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.local_cafe, color: Colors.brown),

                    title: Text(
                      cafe['nama_cafe'] ?? 'Tanpa Nama',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(cafe['alamat'] ?? ''),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuScreen(
                            cafeId: cafe['id'],
                            cafeName: cafe['nama_cafe'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ================= MAPS (LBS) =================

class CafeMapsScreen extends StatefulWidget {
  const CafeMapsScreen({super.key});

  @override
  State<CafeMapsScreen> createState() => _CafeMapsScreenState();
}

class _CafeMapsScreenState extends State<CafeMapsScreen> {
  List cafes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCafes();
  }

  // Mengambil data cafe dari database sama seperti di halaman Home
  Future<void> fetchCafes() async {
    try {
      final data = await CafeService.getCafes();
      setState(() {
        cafes = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error maps: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pusat peta default. Kamu bisa ganti koordinat ini ke kotamu (misal: Yogyakarta/Jakarta)
    final centerMap = const LatLng(
      -7.795580,
      110.369490,
    ); // Default: Titik Nol Yogyakarta

    return Scaffold(
      appBar: AppBar(
        title: const Text("Peta Lokasi Cafe"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : FlutterMap(
              options: MapOptions(initialCenter: centerMap, initialZoom: 13.0),
              children: [
                // Layer peta dasar dari OpenStreetMap (Gratis)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cafe.agregator',
                ),
                // Layer penanda lokasi (Marker)
                MarkerLayer(
                  markers: cafes.map((cafe) {
                    // 🔥 LOGIKA KOORDINAT:
                    // Jika di databasemu belum ada kolom 'latitude' & 'longitude',
                    // sistem akan membuat titik koordinat buatan yang agak menyebar agar tidak bertumpuk
                    double lat = cafe['latitude'] != null
                        ? double.parse(cafe['latitude'].toString())
                        : (centerMap.latitude + (cafes.indexOf(cafe) * 0.005));

                    double lng = cafe['longitude'] != null
                        ? double.parse(cafe['longitude'].toString())
                        : (centerMap.longitude + (cafes.indexOf(cafe) * 0.005));

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.brown),
                            ),
                            child: Text(
                              cafe['nama_cafe'] ?? 'Cafe',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.brown,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}