import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../data/services/menu_service.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final int cafeId;
  final String cafeName;

  const MenuScreen({super.key, required this.cafeId, required this.cafeName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List menus = [];
  List filteredMenus = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = true;

  Map<String, dynamic> cart = {};

  // 🔥 VARIABEL MATA UANG UNIVERSAL (USD, SGD, JPY, KRW, EUR)
  String selectedCurrency = 'IDR';
  Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000062,
    'SGD': 0.000084, // Singapore Dollar
    'JPY': 0.0094, // Japanese Yen
    'KRW': 0.085, // South Korean Won
    'EUR': 0.000058,
  };

  @override
  void initState() {
    super.initState();
    fetchMenus();
    loadCart();
    fetchExchangeRates();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://latest.currency-api.pages.dev/v1/currencies/idr.json',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idrRates = data['idr'];

        setState(() {
          exchangeRates['USD'] = (idrRates['usd'] as num).toDouble();
          exchangeRates['SGD'] = (idrRates['sgd'] as num).toDouble();
          exchangeRates['JPY'] = (idrRates['jpy'] as num).toDouble();
          exchangeRates['KRW'] = (idrRates['krw'] as num).toDouble();
          exchangeRates['EUR'] = (idrRates['eur'] as num).toDouble();
        });
      }
    } catch (e) {
      print("Gagal ambil kurs real-time: $e");
    }
  }

  String formatPrice(dynamic originalPrice) {
    double price = double.parse(originalPrice.toString());
    if (selectedCurrency == 'IDR') {
      return "Rp ${price.toInt()}";
    } else {
      double converted = price * exchangeRates[selectedCurrency]!;
      // JPY dan KRW biasanya tidak menggunakan banyak desimal di belakang koma
      int decimalPlaces =
          (selectedCurrency == 'JPY' || selectedCurrency == 'KRW') ? 0 : 2;
      return "$selectedCurrency ${converted.toStringAsFixed(decimalPlaces)}";
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

  Future<void> fetchMenus() async {
    try {
      final data = await MenuService.getMenus(widget.cafeId);
      setState(() {
        menus = data;
        filteredMenus = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void filterMenus(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredMenus = menus;
      } else {
        filteredMenus = menus.where((menu) {
          final namaMenu = menu['nama_menu'].toString().toLowerCase();
          return namaMenu.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void addToCart(Map<String, dynamic> menu) {
    String menuIdStr = menu['id'].toString();
    setState(() {
      if (cart.containsKey(menuIdStr)) {
        cart[menuIdStr]['jumlah'] += 1;
      } else {
        cart[menuIdStr] = {
          'menu_id': menu['id'],
          'nama_menu': menu['nama_menu'],
          'harga': double.parse(menu['harga'].toString()).toInt(),
          'jumlah': 1,
          'catatan': '',
        };
      }
    });
    saveCart();
  }

  int getTotalItem() {
    int total = 0;
    cart.forEach((key, value) {
      total += (value['jumlah'] as int);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Text(widget.cafeName),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        cafeId: widget.cafeId,
                        cafeName: widget.cafeName,
                        // 🔥 MODIFIKASI: Kirim pilihan mata uang dan rate-nya
                        currency: selectedCurrency,
                        rate: exchangeRates[selectedCurrency]!,
                      ),
                    ),
                  ).then((_) => loadCart());
                },
              ),
              if (getTotalItem() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${getTotalItem()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => filterMenus(value),
                    decoration: InputDecoration(
                      hintText: "Cari menu (ex: Kopi, Aren...)",
                      prefixIcon: const Icon(Icons.search, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Colors.brown,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Colors.brown,
                          width: 2,
                        ),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                filterMenus('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.currency_exchange,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedCurrency,
                        underline: const SizedBox(),
                        items: exchangeRates.keys.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(
                              currency,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCurrency = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredMenus.isEmpty
                      ? const Center(
                          child: Text(
                            "Menu tidak ditemukan 😕",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredMenus.length,
                          itemBuilder: (context, index) {
                            final menu = filteredMenus[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  menu['nama_menu'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  formatPrice(menu['harga']),
                                  style: const TextStyle(
                                    color: Colors.brown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () => addToCart(menu),
                                  child: const Text(
                                    "+ Tambah",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}