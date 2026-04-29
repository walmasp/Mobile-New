import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/booking_service.dart';
import '../../../data/services/table_service.dart';
// 🔥 IMPORT SERVICE NOTIFIKASI
import '../../../data/services/notification_service.dart';

class CheckoutScreen extends StatefulWidget {
  final int cafeId;
  final List<Map<String, dynamic>> items;
  final String currency;
  final double rate;

  const CheckoutScreen({
    super.key,
    required this.cafeId,
    required this.items,
    this.currency = 'IDR',
    this.rate = 1.0,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isLoading = false;
  List tables = [];
  bool isLoadingTables = true;

  int? selectedPeopleCount;
  int? selectedTableId;
  DateTime? selectedDate;
  TimeOfDay? startTime;

  String selectedPayment = 'lunas';

  @override
  void initState() {
    super.initState();
    fetchTables();
  }

  String formatPrice(dynamic originalPrice) {
    double price = double.parse(originalPrice.toString());
    if (widget.currency == 'IDR') {
      return "Rp ${price.toInt()}";
    } else {
      double converted = price * widget.rate;
      int decimalPlaces = (widget.currency == 'JPY' || widget.currency == 'KRW')
          ? 0
          : 2;
      return "${widget.currency} ${converted.toStringAsFixed(decimalPlaces)}";
    }
  }

  Future<void> fetchTables() async {
    try {
      final data = await TableService.getTables(widget.cafeId);
      setState(() {
        tables = data;
        isLoadingTables = false;
      });
    } catch (e) {
      setState(() => isLoadingTables = false);
    }
  }

  String getConvertedTimes() {
    if (startTime == null) return "";
    int wibHour = startTime!.hour;
    int minute = startTime!.minute;
    String minStr = minute.toString().padLeft(2, '0');
    int witaHour = (wibHour + 1) % 24;
    int witHour = (wibHour + 2) % 24;
    int londonHour = (wibHour - 7) % 24;
    if (londonHour < 0) londonHour += 24;

    return "Waktu ini setara dengan:\n"
        "${witaHour.toString().padLeft(2, '0')}:$minStr WITA  |  "
        "${witHour.toString().padLeft(2, '0')}:$minStr WIT  |  "
        "${londonHour.toString().padLeft(2, '0')}:$minStr London";
  }

  Future<void> handleCheckout() async {
    if (selectedPeopleCount == null ||
        selectedTableId == null ||
        selectedDate == null ||
        startTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi data booking!")));
      return;
    }

    setState(() => isLoading = true);

    try {
      String formattedDate = selectedDate!.toString().split(' ')[0];
      String formattedStartTime =
          '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00';
      int endHour = (startTime!.hour + 2) % 24;
      String formattedEndTime =
          '${endHour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00';

      final result = await BookingService.createBooking(
        cafeId: widget.cafeId,
        tableId: selectedTableId!,
        jumlahOrang: selectedPeopleCount!,
        items: widget.items,
        tanggal: formattedDate,
        jamMulai: formattedStartTime,
        jamSelesai: formattedEndTime,
        jenisPembayaran: selectedPayment,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          bool isPaid = false;
          Timer? pollingTimer;

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              pollingTimer ??= Timer.periodic(const Duration(seconds: 3), (
                timer,
              ) async {
                String status = await BookingService.checkStatus(
                  result['booking_id'],
                );
                if (status == 'confirmed' || status == 'selesai') {
                  timer.cancel();

                  // 🔥 PEMICU NOTIFIKASI OTOMATIS SAAT BAYAR BERHASIL
                  await NotificationService.createNotification(
                    "Pembayaran Berhasil! 🎉",
                    "Booking kamu telah dikonfirmasi. Sampai jumpa di lokasi!",
                  );

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('cart_cafe_${widget.cafeId}');
                  setStateDialog(() => isPaid = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  });
                }
              });

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPaid) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Pembayaran Berhasil!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Selesaikan Pembayaran",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tagihan Anda:\n${formatPrice(result['tagihan_sekarang'] ?? result['total_harga'] ?? 0)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.qr_code_2,
                        size: 150,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Colors.brown),
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal booking: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: isLoadingTables
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    "Jumlah Orang",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text("Pilih jumlah orang"),
                    value: selectedPeopleCount,
                    items: List.generate(10, (index) => index + 1)
                        .map(
                          (val) => DropdownMenuItem(
                            value: val,
                            child: Text("$val Orang"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      selectedPeopleCount = val;
                      selectedTableId = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Pilih Nomor Meja Utama",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tables.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final isSelected = selectedTableId == table['id'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedTableId = table['id']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.brown : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.brown),
                          ),
                          child: Center(
                            child: Text(
                              "Meja ${table['nomor_meja']}",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Tanggal & Jam",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (p != null) setState(() => selectedDate = p);
                          },
                          child: Text(
                            selectedDate == null
                                ? "Pilih Tanggal"
                                : selectedDate.toString().split(' ')[0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final p = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (p != null) setState(() => startTime = p);
                          },
                          child: Text(
                            startTime == null
                                ? "Pilih Jam"
                                : startTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (startTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        getConvertedTimes(),
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    "Jenis Pembayaran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile(
                    title: const Text("Lunas"),
                    value: 'lunas',
                    groupValue: selectedPayment,
                    onChanged: (v) => setState(() => selectedPayment = v!),
                  ),
                  RadioListTile(
                    title: const Text("DP 50%"),
                    value: 'dp_50',
                    groupValue: selectedPayment,
                    onChanged: (v) => setState(() => selectedPayment = v!),
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: handleCheckout,
                          child: const Text(
                            "Konfirmasi Booking",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}