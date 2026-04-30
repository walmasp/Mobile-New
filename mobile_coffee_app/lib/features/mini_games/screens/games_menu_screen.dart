import 'package:flutter/material.dart';
import 'barista_balance_screen.dart';
import 'latte_art_maker_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Kafe Mini Games"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Pilih Game & Menangkan Diskon!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 20),

          // --- KARTU GAME 1: BARISTA BALANCE ---
          _buildGameCard(
            context: context,
            title: "Barista Balance",
            description:
                "Uji keseimbangan tanganmu menjaga kopi agar tidak tumpah menggunakan Accelerometer.",
            icon: Icons.balance,
            color: Colors.brown[400]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BaristaBalanceScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 15),

          // --- KARTU GAME 2: LATTE ART MAKER ---
          _buildGameCard(
            context: context,
            title: "Latte Art Maker",
            description:
                "Putar HP-mu perlahan untuk menuangkan susu dan membuat pola hati menggunakan Gyroscope.",
            icon: Icons.coffee_maker,
            color: Colors.brown[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LatteArtMakerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Fungsi bantuan untuk membuat UI Kartu agar rapi
  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
