import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔥 1. INISIALISASI (Panggil ini di main.dart nanti)
  static Future<void> init() async {
    // Ikon notifikasi (pastikan kamu punya ikon mipmap/ic_launcher di folder android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfigurasi untuk iOS (jika butuh)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // 🔥 PERBAIKAN: Tambahkan parameter aksi saat notifikasi diklik
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("User mengeklik notifikasi!");
        // Kamu bisa mengarahkan user ke halaman history nanti di sini
      },
    );
  }

  // 🔥 2. FUNGSI MEMUNCULKAN POP-UP DARI ATAS
  static Future<void> showPopUpNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // KUNCI UTAMA: Importance.max dan Priority.high bikin notif muncul dari atas!
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'cafe_channel_id', // ID Channel (bebas)
          'Pemberitahuan Cafe', // Nama Channel (muncul di setting HP)
          channelDescription: 'Notifikasi untuk pembayaran dan reservasi',
          importance: Importance.max, // Wajib Max
          priority: Priority.high, // Wajib High
          playSound: true, // Biar ada suaranya
          enableVibration: true, // Biar bergetar
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // 🔥 PERBAIKAN: Hapus nama parameter (id:, title:, dll) karena formatnya positional
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
