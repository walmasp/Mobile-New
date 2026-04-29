import 'package:flutter/material.dart';
import '../../features/mini_games/screens/barista_balance_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../data/services/cafe_service.dart';
import '../../features/menu/screens/menu_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CafeHomeScreen(),
    const CafeMapsScreen(),
    const BaristaBalanceScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Game'),
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

// ================= MAPS =================

class CafeMapsScreen extends StatelessWidget {
  const CafeMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Ini Halaman Peta LBS", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}