import 'package:flutter/material.dart';
import 'package:kasirku/pages/user/user_page.dart';
import 'package:kasirku/pages/barang/barang_page.dart';
import 'package:kasirku/pages/login_page.dart';
import 'package:kasirku/pages/transaksi/kasir_page.dart';
import 'package:kasirku/pages/transaksi/transaksi_page.dart';
import 'package:kasirku/pages/toko_settings_page.dart';
import 'package:kasirku/pages/laporan_page.dart';
import 'package:kasirku/models/toko.dart';
import 'package:kasirku/database/database_helper.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String namaUser = "User";
  String role = "";
  Toko? shopInfo;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final shop = await DatabaseHelper.instance.getToko();
    setState(() {
      namaUser = prefs.getString('namaUser') ?? "User";
      role = prefs.getString('role') ?? "";
      shopInfo = shop;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget _menuCard(
    String title,
    IconData icon,
    Color color,
    Widget page, {
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
              if (result == true) {
                _loadUser();
              }
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Akses ditolak: Hanya Admin")),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isEnabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
              child: Icon(icon, color: isEnabled ? color : Colors.grey, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isEnabled ? Colors.black : Colors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [

          // HEADER MODERN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (shopInfo?.logo != null)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(shopInfo!.logo!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                "K",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          shopInfo?.namaToko ?? "KasirKu",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    )
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "Halo, $namaUser 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  "Selamat bekerja hari ini",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // MENU GRID
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [

                  _menuCard(
                    "Data Barang",
                    Icons.inventory_2,
                    Colors.orange,
                    const BarangPage(),
                  ),

                  _menuCard(
                    "Kasir / POS",
                    Icons.point_of_sale,
                    Colors.blue,
                    const KasirPage(),
                  ),

                  _menuCard(
                    "Data User",
                    Icons.people,
                    Colors.green,
                    const UserPage(),
                    isEnabled: role == 'admin',
                  ),
                  
                    _menuCard(
                      "Riwayat Transaksi",
                      Icons.history,
                      Colors.purple,
                      const TransaksiPage(),
                    ),

                    _menuCard(
                      "Pengaturan Toko",
                      Icons.settings,
                      Colors.blueGrey,
                      const TokoSettingsPage(),
                      isEnabled: role == 'admin',
                    ),
                    
                    _menuCard(
                      "Laporan",
                      Icons.bar_chart,
                      Colors.teal,
                      const LaporanPage(),
                      isEnabled: role == 'admin',
                    ),
                  ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}