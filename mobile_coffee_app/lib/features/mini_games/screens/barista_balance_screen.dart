import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart'; // 🔥 IMPORT SENSOR CAHAYA

class BaristaBalanceScreen extends StatefulWidget {
  const BaristaBalanceScreen({super.key});

  @override
  State<BaristaBalanceScreen> createState() => _BaristaBalanceScreenState();
}

class _BaristaBalanceScreenState extends State<BaristaBalanceScreen> {
  // --- Variabel Game & Accelerometer ---
  int _timeLeft = 30;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  bool _isPlaying = false;
  bool _isGameOver = false;
  double _x = 0.0;
  double _y = 0.0;
  final double _threshold = 4.5;

  // --- Variabel Light Sensor (Sensor Cahaya) ---
  Light? _light;
  StreamSubscription<int>? _lightSubscription;
  int _luxValue = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initLightSensor();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    _lightSubscription?.cancel();
    super.dispose();
  }

  // 🔥 PENGAMAN SENSOR CAHAYA
  void _initLightSensor() {
    _light = Light();
    try {
      _lightSubscription = _light?.lightSensorStream.listen(
        (int luxValue) {
          if (!mounted) return;
          setState(() {
            _luxValue = luxValue;
            _isDarkMode = luxValue < 15;
          });
        },
        onError: (error) {
          print("Sensor Cahaya tidak didukung di HP ini: $error");
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Gagal inisiasi sensor cahaya: $e");
    }
  }

  void _startGame() {
    setState(() {
      _timeLeft = 30;
      _isPlaying = true;
      _isGameOver = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _winGame();
      }
    });

    // 🔥 PENGAMAN ACCELEROMETER
    try {
      _sensorSubscription = accelerometerEventStream().listen(
        (event) {
          if (_isPlaying) {
            setState(() {
              _x = event.x;
              _y = event.z;
            });

            if (_x > _threshold ||
                _x < -_threshold ||
                _y > _threshold ||
                _y < -_threshold) {
              _loseGame();
            }
          }
        },
        onError: (error) {
          print("Accelerometer tidak didukung: $error");
          _loseGame();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Gagal inisiasi Accelerometer: $e");
    }
  }

  void _loseGame() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _winGame() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    setState(() {
      _isPlaying = false;
    });

    // Notifikasi dimatikan sementara agar tidak error
    // await NotificationService.createNotification(...);

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
          title: const Text("🎉 SELAMAT! 🎉", textAlign: TextAlign.center),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_cafe, size: 60, color: Colors.brown),
              SizedBox(height: 15),
              Text(
                "Kamu jago menyeimbangkan kopi!\n\nTunjukkan layar ini ke kasir saat check-in untuk klaim Gorengan Gratis / Diskon 10%.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Tutup & Klaim Nanti"),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.brown[50]!;
    Color textColor = _isDarkMode ? Colors.white : Colors.black87;
    Color appBarColor = _isDarkMode ? Colors.black87 : Colors.brown;
    Color iconBgColor = _isDarkMode ? Colors.grey[800]! : Colors.brown[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Barista Balance"),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.brown),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: _isDarkMode ? Colors.yellow : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Cahaya: $_luxValue Lux",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _isPlaying
                  ? "Pegang HP-mu tegak lurus!"
                  : _isGameOver
                  ? "Yah, kopinya tumpah! 😭"
                  : "Siap jadi Barista?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Waktu: $_timeLeft s",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _timeLeft <= 10
                    ? Colors.red
                    : (_isDarkMode ? Colors.brown[200] : Colors.brown),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Transform.translate(
                offset: Offset(_x * -15, _y * 15),
                child: Icon(
                  _isGameOver ? Icons.water_drop : Icons.local_cafe,
                  size: 80,
                  color: _isGameOver
                      ? Colors.blue
                      : (_isDarkMode ? Colors.brown[100] : Colors.brown[800]),
                ),
              ),
            ),
            const SizedBox(height: 60),
            if (!_isPlaying)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode
                      ? Colors.brown[400]
                      : Colors.brown,
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
                  _isGameOver ? "Coba Lagi" : "Mulai Game",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
