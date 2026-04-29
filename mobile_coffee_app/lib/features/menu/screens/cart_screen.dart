import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../booking/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final int cafeId;
  final String cafeName;
  // 🔥 TAMBAHAN: Terima data mata uang dari Menu
  final String currency;
  final double rate;

  const CartScreen({
    super.key,
    required this.cafeId,
    required this.cafeName,
    this.currency = 'IDR', // Default IDR jika tidak dikirim
    this.rate = 1.0, // Default rate 1.0
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic> cart = {};

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  // 🔥 FUNGSI FORMAT HARGA (Logika sama dengan di Menu)
  String formatPrice(dynamic originalPrice) {
    double price = double.parse(originalPrice.toString());
    if (widget.currency == 'IDR') {
      return "Rp ${price.toInt()}";
    } else {
      double converted = price * widget.rate;
      // JPY dan KRW biasanya tidak menggunakan desimal
      int decimalPlaces = (widget.currency == 'JPY' || widget.currency == 'KRW')
          ? 0
          : 2;
      return "${widget.currency} ${converted.toStringAsFixed(decimalPlaces)}";
    }
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedCart = prefs.getString('cart_cafe_${widget.cafeId}');
    if (savedCart != null) {
      setState(() {
        cart = jsonDecode(savedCart);
      });
    }
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_cafe_${widget.cafeId}', jsonEncode(cart));
  }

  void updateQuantity(String menuIdStr, int change) {
    setState(() {
      cart[menuIdStr]['jumlah'] += change;
      if (cart[menuIdStr]['jumlah'] <= 0) {
        cart.remove(menuIdStr);
      }
    });
    saveCart();
  }

  void deleteItem(String menuIdStr) {
    setState(() {
      cart.remove(menuIdStr);
    });
    saveCart();
  }

  void updateNote(String menuIdStr, String note) {
    cart[menuIdStr]['catatan'] = note;
    saveCart();
  }

  int getTotalPrice() {
    int total = 0;
    cart.forEach((key, item) {
      total += (item['harga'] as int) * (item['jumlah'] as int);
    });
    return total;
  }

  void goToCheckout() {
    List<Map<String, dynamic>> items = cart.values.map((item) {
      return {
        "menu_id": item['menu_id'],
        "jumlah": item['jumlah'],
        "catatan": item['catatan'],
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cafeId: widget.cafeId,
          items: items,
          // 🔥 OPER LAGI DATA MATA UANG KE CHECKOUT
          currency: widget.currency,
          rate: widget.rate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> cartKeys = cart.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Keranjang'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: cart.isEmpty
          ? const Center(child: Text("Keranjang kamu masih kosong."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartKeys.length,
              itemBuilder: (context, index) {
                String key = cartKeys[index];
                var item = cart[key];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['nama_menu'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => deleteItem(key),
                            ),
                          ],
                        ),
                        // 🔥 GUNAKAN FUNGSI FORMAT HARGA DI SINI
                        Text(
                          formatPrice(item['harga']),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller:
                              TextEditingController(text: item['catatan'])
                                ..selection = TextSelection.collapsed(
                                  offset: (item['catatan'] ?? "").length,
                                ),
                          decoration: const InputDecoration(
                            hintText:
                                'Tambah catatan (mis. less ice, less sugar)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                          ),
                          onChanged: (value) => updateNote(key, value),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => updateQuantity(key, -1),
                            ),
                            Text(
                              '${item['jumlah']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => updateQuantity(key, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(color: Colors.grey),
                        ),
                        // 🔥 GUNAKAN FUNGSI FORMAT HARGA DI TOTAL PEMBAYARAN
                        Text(
                          formatPrice(getTotalPrice()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: goToCheckout,
                      child: const Text(
                        'Lanjut Pilih Meja',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}