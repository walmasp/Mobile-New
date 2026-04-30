import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
// Sesuaikan import ini jika letaknya berbeda
import '../../../data/services/notification_service.dart';

class LatteArtMakerScreen extends StatefulWidget {
  const LatteArtMakerScreen({super.key});

  @override
  State<LatteArtMakerScreen> createState() => _LatteArtMakerScreenState();
}

class _LatteArtMakerScreenState extends State<LatteArtMakerScreen> {
  // Variabel Timer & Sensor
  int _timeLeft = 20;
  Timer? _timer;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Status Game
  bool _isPlaying = false;
  bool _isGameOver = false;

  // Variabel Progress Susu (0 - 100)
  double _milkPoured = 0.0;
  String _pourStatus = "Siap menuang...";

  @override
  void dispose() {
    _timer?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _timeLeft = 20;
      _milkPoured = 0.0;
      _isPlaying = true;
      _isGameOver = false;
      _pourStatus = "Miringkan HP ke depan perlahan...";
    });

    // 1. Timer Mundur
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        // Waktu habis, gagal mencapai 100%
        if (_milkPoured < 100) _loseGame("Waktu habis! Kopi keburu dingin.");
      }
    });

    // 2. Deteksi Rotasi Gyroscope
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (_isPlaying) {
        setState(() {
          // event.x mendeteksi putaran ke depan/belakang (Pitch)
          double twistSpeed = event.x;

          // Jika putaran ke depan halus (0.5 sampai 2.5 rad/s)
          if (twistSpeed > 0.3 && twistSpeed <= 2.5) {
            _pourStatus = "Menuang Halus... ✨";
            // Tambah progress berdasarkan kecepatan (makin cepat makin banyak, tapi rawan tumpah)
            _milkPoured += (twistSpeed * 1.5);
            if (_milkPoured >= 100) {
              _milkPoured = 100;
              _winGame();
            }
          }
          // Jika putaran terlalu barbar (lebih dari 2.5 rad/s)
          else if (twistSpeed > 2.5) {
            _loseGame("Terlalu cepat! Susunya tumpah berantakan! 💦");
          }
          // Jika diam atau malah diputar ke belakang
          else if (twistSpeed < 0) {
            _pourStatus = "Ayo tuang, putar perlahan ke depan.";
          }
        });
      }
    });
  }

  void _loseGame(String reason) {
    _timer?.cancel();
    _gyroSubscription?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      _pourStatus = reason;
    });
  }

  void _winGame() async {
    _timer?.cancel();
    _gyroSubscription?.cancel();
    setState(() {
      _isPlaying = false;
      _pourStatus = "Latte Art Sempurna! 🤎";
    });

    // Kirim notifikasi kemenangan
    await NotificationService.createNotification(
      "Master Latte Art! 🎨",
      "Pola hatimu sangat rapi! Dapatkan ekstra diskon 5% dengan menunjukkan ini di kasir.",
    );

    _showPrizeDialog();
  }

  void _showPrizeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.brown[50],
          title: const Text(
            "✨ LUAR BIASA! ✨",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.brown),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.brown[200]?.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.coffee_maker,
                  size: 60,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Tanganmu sangat stabil!\n\nKamu berhasil membuat Latte Art yang sempurna. Klaim diskon tambahan di kasir ya!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Tutup & Klaim",
                  style: TextStyle(color: Colors.white),
                ),
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
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: const Text("Latte Art Maker"),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kotak Informasi Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.brown[300]!, width: 2),
                ),
                child: Text(
                  _pourStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isGameOver ? Colors.red : Colors.brown[800],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Visualisasi Gelas dan Progress Susu
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Latar Gelas Hitam (Kopi)
                  Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      border: Border.all(color: Colors.grey[400]!, width: 4),
                    ),
                  ),
                  // Lapisan Susu (Putih) yang bergerak naik
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width:
                        142, // Sedikit lebih kecil agar masuk ke dalam border
                    height: (200 * (_milkPoured / 100))
                        .clamp(0, 192)
                        .toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: _milkPoured >= 95
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(26),
                            )
                          : const BorderRadius.only(
                              bottomLeft: Radius.circular(26),
                              bottomRight: Radius.circular(26),
                            ),
                    ),
                  ),
                  // Indikator Angka Persentase di Tengah Gelas
                  Positioned(
                    bottom: 80,
                    child: Text(
                      "${_milkPoured.toInt()}%",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: _milkPoured > 50 ? Colors.brown : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Timer Teks
              Text(
                "Sisa Waktu: $_timeLeft s",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 5 ? Colors.red : Colors.brown[800],
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Mulai / Main Lagi
              if (!_isPlaying)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _startGame,
                  child: Text(
                    _isGameOver || _milkPoured >= 100
                        ? "Main Lagi"
                        : "Mulai Tuang",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
