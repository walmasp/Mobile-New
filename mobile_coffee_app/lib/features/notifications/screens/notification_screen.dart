import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🔥 Import disesuaikan dengan struktur folder barumu (mundur 3 folder)
import '../../../core/config/api_config.dart';
import '../../../core/utils/auth_helper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings/notifications/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : notifications.isEmpty
          ? const Center(child: Text("Belum ada notifikasi 🔕"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(
                      notif['judul'] ?? 'Notifikasi',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(notif['pesan'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}