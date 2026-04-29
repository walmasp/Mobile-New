import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  int? jumlahOrang;
  String? mejaTerpilih;

  // Contoh list meja sementara (Nantinya data ini diambil dari table_service.dart)
  List<String> mejaAvailable = [
    'Meja 01 (Kapasitas 4)',
    'Meja 02 (Kapasitas 6)',
    'Meja 05 (Kapasitas 15)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Meja')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silakan isi detail reservasi:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 1. INPUT JUMLAH ORANG
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Orang',
                  hintText: 'Maksimal 15 orang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah orang wajib diisi!';
                  }
                  int? val = int.tryParse(value);
                  if (val == null || val <= 0) {
                    return 'Masukkan angka yang valid!';
                  }
                  if (val > 15) return 'Maksimal 15 orang untuk 1 reservasi.';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    jumlahOrang = int.tryParse(value);
                    // Reset pilihan meja jika jumlah orang berubah
                    mejaTerpilih = null;

                    // TODO: Panggil table_service.dart di sini untuk
                    // fetch ulang mejaAvailable sesuai jumlahOrang
                  });
                },
              ),

              const SizedBox(height: 24),

              // 2. DROPDOWN PILIH MEJA
              // Dropdown hanya aktif jika jumlah orang sudah diisi dengan benar
              DropdownButtonFormField<String>(
                initialValue: mejaTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Pilih Meja',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
                hint: const Text('Pilih Meja Tersedia'),
                items:
                    jumlahOrang != null &&
                        jumlahOrang! > 0 &&
                        jumlahOrang! <= 15
                    ? mejaAvailable.map((String meja) {
                        return DropdownMenuItem<String>(
                          value: meja,
                          child: Text(meja),
                        );
                      }).toList()
                    : null, // Dropdown disable (abu-abu) kalau belum isi jumlah orang
                onChanged: (String? newValue) {
                  setState(() {
                    mejaTerpilih = newValue;
                  });
                },
                validator: (value) => value == null
                    ? 'Silakan pilih meja terlebih dahulu!'
                    : null,
              ),

              const Spacer(),

              // TOMBOL LANJUT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Validasi form sebelum lanjut
                    if (_formKey.currentState!.validate()) {
                      // Jika valid, arahkan ke halaman Menu atau Checkout
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Meja $mejaTerpilih berhasil dibooking untuk $jumlahOrang orang!',
                          ),
                        ),
                      );
                      // Navigator.pushNamed(context, '/menu'); // Contoh routing
                    }
                  },
                  child: const Text(
                    'Lanjut Pilih Menu',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
