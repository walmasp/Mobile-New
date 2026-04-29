import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
// 🔥 IMPORT SERVICE NOTIFIKASI
import '../../../data/services/notification_service.dart';

class BaristaBalanceScreen extends StatefulWidget {
  const BaristaBalanceScreen({super.key});

  @override
  State<BaristaBalanceScreen> createState() => _BaristaBalanceScreenState();
}

class _BaristaBalanceScreenState extends State<BaristaBalanceScreen> {
  int _timeLeft = 30;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  bool _isPlaying = false;
  bool _isGameOver = false;

  double _x = 0.0;
  double _y = 0.0;

  final double _threshold = 4.5;

  @override
  void dispose() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
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

    _sensorSubscription = accelerometerEventStream().listen((event) {
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
    });
  }

  void _loseGame() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _winGame() async {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    setState(() {
      _isPlaying = false;
    });

    // 🔥 PEMICU NOTIFIKASI SAAT MENANG GAME
    await NotificationService.createNotification(
      "Juara Barista! ☕",
      "Selamat! Kamu berhasil menjaga keseimbangan kopi. Klaim hadiahmu di kasir!",
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Barista Balance"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isPlaying
                  ? "Pegang HP-mu tegak lurus!"
                  : _isGameOver
                  ? "Yah, kopinya tumpah! 😭"
                  : "Siap jadi Barista?",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Waktu: $_timeLeft s",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _timeLeft <= 10 ? Colors.red : Colors.brown,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.brown[200],
                shape: BoxShape.circle,
              ),
              child: Transform.translate(
                offset: Offset(_x * -15, _y * 15),
                child: Icon(
                  _isGameOver ? Icons.water_drop : Icons.local_cafe,
                  size: 80,
                  color: _isGameOver ? Colors.blue : Colors.brown[800],
                ),
              ),
            ),
            const SizedBox(height: 60),
            if (!_isPlaying)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
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