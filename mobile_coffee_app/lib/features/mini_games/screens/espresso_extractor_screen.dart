import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 IMPORT BARU[cite: 14]

class EspressoExtractorScreen extends StatefulWidget {
  const EspressoExtractorScreen({super.key});

  @override
  State<EspressoExtractorScreen> createState() =>
      _EspressoExtractorScreenState();
}

class _EspressoExtractorScreenState extends State<EspressoExtractorScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  String _status = "Siap mengekstrak!";
  double _coffeeExtracted = 0.0;
  double _heatLevel = 0.0;
  bool _isNear = false;
  StreamSubscription<int>? _proximitySubscription;
  Timer? _gameLoopTimer;

  @override
  void initState() {
    super.initState();
    _initProximitySensor();
  }

  @override
  void dispose() {
    _proximitySubscription?.cancel();
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  // 🔥 FUNGSI BARU: TAMBAH 2 POIN KE DATABASE LOKAL[cite: 14]
  Future<void> _addPoints() async {
    final prefs = await SharedPreferences.getInstance();
    int currentPoints = prefs.getInt('total_points') ?? 0;
    await prefs.setInt('total_points', currentPoints + 2);
  }

  void _initProximitySensor() {
    try {
      _proximitySubscription = ProximitySensor.events.listen(
        (int event) {
          if (!mounted) return;
          setState(() {
            _isNear = (event > 0);
          });
        },
        onError: (error) {
          print("Proximity Sensor Error: $error");
          if (mounted) {
            setState(() {
              _status = "Sensor jarak tidak ada di HP ini 😭";
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Gagal inisiasi sensor proximity: $e");
    }
  }

  void _startGame() {
    setState(() {
      _coffeeExtracted = 0.0;
      _heatLevel = 0.0;
      _isPlaying = true;
      _isGameOver = false;
      _status = "Tutup layar atas dengan jari!";
    });

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) return;

      setState(() {
        if (_isNear) {
          _coffeeExtracted += 0.6;
          _heatLevel += 1.8;
          _status = "Mengekstrak... Tahan!";
          if (_heatLevel >= 80) _status = "AWAS PANAS! Lepas jarimu!";
        } else {
          _heatLevel -= 3.0;
          if (_heatLevel < 0) _heatLevel = 0;
          if (_coffeeExtracted > 0) _status = "Suhu aman. Tutup lagi!";
        }

        if (_heatLevel >= 100) {
          _loseGame("Mesin Overheat! Kopi hangus 🔥");
        } else if (_coffeeExtracted >= 100) {
          _coffeeExtracted = 100;
          _winGame();
        }
      });
    });
  }

  void _loseGame(String reason) {
    _gameLoopTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      _status = reason;
    });
  }

  // 🔥 UPDATE: MENAMBAHKAN POIN SAAT MENANG[cite: 14]
  void _winGame() async {
    _gameLoopTimer?.cancel();
    await _addPoints(); // Simpan 2 poin reward

    setState(() {
      _isPlaying = false;
      _status = "Espresso Sempurna! +2 Poin ☕";
    });

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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.coffee, size: 60, color: Colors.brown),
              SizedBox(height: 15),
              Text(
                "Kamu berhasil mengekstrak Espresso! \n\nKamu mendapatkan +2 Poin Reward. Cek di profilmu!",
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
                  "Tutup",
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
    Color heatColor = Colors.green;
    if (_heatLevel > 60) heatColor = Colors.orange;
    if (_heatLevel > 85) heatColor = Colors.red;

    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: const Text("Espresso Extractor"),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.brown[300]!, width: 2),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isGameOver ? Colors.red : Colors.brown[800],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Hasil Ekstraksi Kopi:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: _coffeeExtracted / 100,
                  minHeight: 30,
                  backgroundColor: Colors.brown[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[800]!),
                ),
              ),
              Text(
                "${_coffeeExtracted.toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Suhu Mesin (Jangan sampai penuh!):",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: _heatLevel / 100,
                  minHeight: 20,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(heatColor),
                ),
              ),
              Text(
                "${_heatLevel.toInt()}°C",
                style: TextStyle(fontWeight: FontWeight.bold, color: heatColor),
              ),
              const SizedBox(height: 60),
              Transform.translate(
                offset: Offset(
                  (_heatLevel > 80 && _isNear) ? (_heatLevel % 3 - 1.5) * 2 : 0,
                  0,
                ),
                child: Icon(
                  Icons.coffee_maker_rounded,
                  size: 100,
                  color: _heatLevel > 80 ? Colors.red : Colors.brown[700],
                ),
              ),
              const SizedBox(height: 40),
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
                    _isGameOver || _coffeeExtracted >= 100
                        ? "Main Lagi"
                        : "Mulai Ekstraksi",
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
