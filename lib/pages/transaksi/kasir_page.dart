import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kasirku/database/database_helper.dart';
import 'package:kasirku/models/barang.dart';
import 'package:kasirku/models/transaksi.dart';
import 'package:kasirku/models/detail_transaksi.dart';
import 'package:kasirku/pages/transaksi/struk_page.dart';
import 'package:kasirku/services/telegram_service.dart';
import 'package:kasirku/models/toko.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  List<Barang> _allBarang = [];
  final List<Map<String, dynamic>> _cart = [];
  final TextEditingController _barcodeController = TextEditingController();

  int _totalHarga = 0;
  int _idKasir = 1; // Default, bisa diubah dari SharedPreferences
  String _namaKasir = "Kasir";

  @override
  void initState() {
    super.initState();
    _loadBarang();
    _loadUserInfo();
  }

  Future<void> _loadBarang() async {
    final barang = await DatabaseHelper.instance.getAllBarang();
    setState(() {
      _allBarang = barang;
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final namaUser = prefs.getString('namaUser') ?? "Kasir";
    int idUser = prefs.getInt('idUser') ?? 0;

    // Fix for old sessions where idUser was not saved
    if (idUser == 0 && namaUser != "Kasir") {
      final users = await DatabaseHelper.instance.getAllUser();
      final found = users.where((u) => u.namaUser == namaUser).firstOrNull;
      if (found != null && found.idUser != null) {
        idUser = found.idUser!;
        await prefs.setInt('idUser', idUser);
      }
    }

    if (idUser == 0) idUser = 1;

    setState(() {
      _namaKasir = namaUser;
      _idKasir = idUser;
    });
  }

  void _cariBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    final barang = await DatabaseHelper.instance.getBarangByBarcode(barcode);

    if (barang != null) {
      if (barang.stok > 0) {
        _tambahKeCart(barang);
      } else {
        _showSnackBar("Stok barang habis!", Colors.red);
      }
    } else {
      _showSnackBar("Barang tidak ditemukan", Colors.red);
    }

    _barcodeController.clear();
  }

  void _tambahKeCart(Barang barang) {
    setState(() {
      // Cek apakah barang sudah ada di cart
      final existingIndex = _cart.indexWhere((item) => item['barang'].idBarang == barang.idBarang);

      if (existingIndex >= 0) {
        // Jika sudah ada, tambahkan jumlah
        final currentQty = _cart[existingIndex]['jumlah'] as int;
        if (currentQty < barang.stok) {
          _cart[existingIndex]['jumlah'] = currentQty + 1;
          _cart[existingIndex]['subtotal'] = (currentQty + 1) * barang.hargaJual;
        } else {
          _showSnackBar("Stok tidak mencukupi!", Colors.orange);
          return;
        }
      } else {
        // Jika belum ada, tambahkan baru
        _cart.add({
          'barang': barang,
          'jumlah': 1,
          'harga': barang.hargaJual,
          'subtotal': barang.hargaJual,
        });
      }

      _hitungTotal();
    });
  }

  void _hapusDariCart(int index) {
    setState(() {
      _cart.removeAt(index);
      _hitHittotal();
    });
  }

  void _ubahJumlah(int index, int perubahan) {
    setState(() {
      final barang = _cart[index]['barang'] as Barang;
      final currentQty = _cart[index]['jumlah'] as int;
      final newQty = currentQty + perubahan;

      if (newQty > 0 && newQty <= barang.stok) {
        _cart[index]['jumlah'] = newQty;
        _cart[index]['subtotal'] = newQty * barang.hargaJual;
        _hitungTotal();
      } else if (newQty <= 0) {
        _hapusDariCart(index);
      }
    });
  }

  void _hitungTotal() {
    setState(() {
      _totalHarga = _cart.fold(0, (sum, item) => sum + (item['subtotal'] as int));
    });
  }

  // Typo fix
  void _hitHittotal() {
    _hitungTotal();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath, String heroTag) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: heroTag,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  Future<void> _bayar() async {
    if (_cart.isEmpty) {
      _showSnackBar("Keranjang kosong!", Colors.orange);
      return;
    }

    // Show dialog pembayaran
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _PembayaranDialog(totalHarga: _totalHarga),
    );
 
    if (result != null && result['bayar'] != null) {
      // Simpan transaksi
      await _simpanTransaksi(result['bayar']!, result['kembalian']!);
    }
  }

  Future<void> _simpanTransaksi(int bayarNominal, int kembalianNominal) async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final tglTransaksi = now.toIso8601String();

    // Hitung kembalian dari controller dialog (simplified)
    // Untuk simplicity, kita langsung simpan
    // Nilai kembalian akan dihitung di dialog

    // Generate nomor transaksi format KS/YYYY/MM/XXXX
    final nomorTransaksi = await db.generateNomorTransaksi();

    // Insert transaksi utama
    final transaksi = Transaksi(
      nomorTransaksi: nomorTransaksi,
      idToko: 1, // Default, bisa dari tabel toko
      idKasir: _idKasir,
      tglTransaksi: tglTransaksi,
      totalHarga: _totalHarga.toDouble(),
      bayar: bayarNominal.toDouble(),
      kembalian: kembalianNominal.toDouble(),
    );

    final idTransaksi = await db.insertTransaksi(transaksi);

    // Insert detail transaksi & kurangi stok
    for (var item in _cart) {
      final barang = item['barang'] as Barang;
      final jumlah = item['jumlah'] as int;
      final harga = item['harga'] as int;
      final subtotal = item['subtotal'] as int;

      // Insert detail
      final detail = DetailTransaksi(
        idTransaksi: idTransaksi,
        idBarang: barang.idBarang!,
        jumlah: jumlah,
        hargaAtTime: harga,
        subtotal: subtotal,
      );
      await db.insertDetailTransaksi(detail);

      // Kurangi stok
      final newStok = barang.stok - jumlah;
      await db.updateStokBarang(barang.idBarang!, newStok);
    }

    if (!mounted) return;
    _showSnackBar("Transaksi berhasil disimpan!", Colors.green);

    // Send Telegram Notification
    try {
      final Toko? toko = await db.getToko();
      if (toko != null) {
        final double totalOmset = await db.getTotalOmset();
        await TelegramService.sendNotification(
          transaksi: transaksi,
          namaKasir: _namaKasir,
          saldoSetelah: totalOmset,
        );
      }
    } catch (e) {
      print("Telegram notification failed: $e");
    }

    if (!mounted) return;
    // Navigate to StrukPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StrukPage(idTransaksi: idTransaksi),
      ),
    ).then((_) {
      if (!mounted) return;
      // Execute clear cart only when returned from StrukPage or immediately
      setState(() {
        _cart.clear();
        _totalHarga = 0;
      });
      // Refresh barang
      _loadBarang();
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kosongkan Keranjang"),
        content: const Text("Yakin ingin mengosongkan keranjang?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cart.clear();
                _totalHarga = 0;
              });
              Navigator.pop(context);
            },
            child: const Text("Ya", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kasir / POS", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCart,
              tooltip: "Kosongkan Keranjang",
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Kasir: $_namaKasir", style: const TextStyle(color: Colors.white)),
                    Text("Items: ${_cart.length}", style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                // Input Barcode
                TextField(
                  controller: _barcodeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Scan atau ketik kode barcode...",
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _cariBarcode,
                ),
              ],
            ),
          ),

          // Available Items (Grid Select)
          Expanded( // Gunakan Expanded agar Grid mengisi sisa ruang yang ada
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Katalog Barang",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: _allBarang.isEmpty
              ? const Center(child: Text("Tidak ada barang tersedia"))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  // Mengatur konfigurasi grid
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Jumlah kolom (misal: 3 kolom)
                    childAspectRatio: 0.75, // Perbandingan lebar & tinggi kartu
                    crossAxisSpacing: 10, // Jarak antar kolom
                    mainAxisSpacing: 10,   // Jarak antar baris
                  ),
                  itemCount: _allBarang.length,
                  itemBuilder: (context, index) {
                    final barang = _allBarang[index];
                    final isOutOfStock = barang.stok <= 0;
                    return GestureDetector(
                      onTap: isOutOfStock ? null : () => _tambahKeCart(barang),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey[100] : Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isOutOfStock)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: barang.foto != null
                                        ? () => _showImagePreview(context, barang.foto!, 'kasir_preview_${barang.idBarang}')
                                        : null,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: barang.foto != null
                                          ? Hero(
                                              tag: 'kasir_preview_${barang.idBarang}',
                                              child: Opacity(
                                                opacity: isOutOfStock ? 0.5 : 1.0,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    File(barang.foto!),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Icon(Icons.inventory_2, color: isOutOfStock ? Colors.grey : Colors.blueAccent, size: 40),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  barang.namaBarang,
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w500,
                                    color: isOutOfStock ? Colors.grey : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatCurrency(barang.hargaJual),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOutOfStock ? Colors.grey : Colors.green,
                                  ),
                                ),
                                Text(
                                  "Stok: ${barang.stok}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isOutOfStock ? Colors.black : (barang.stok < 5 ? Colors.red : Colors.grey),
                                    fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            if (isOutOfStock)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "STOK HABIS",
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  ),
),
        ],
      ),
      bottomNavigationBar: _cart.isEmpty
          ? const SizedBox() // Don't show bottom bar if cart is empty
          : GestureDetector(
              onTap: _showCartBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            "${_cart.length} Item",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            formatCurrency(_totalHarga),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_up, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle indicator for bottom sheet
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Keranjang Anda",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text("Keranjang kosong"))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              final barang = item['barang'] as Barang;
                              final jumlah = item['jumlah'] as int;
                              final subtotal = item['subtotal'] as int;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey[50],
                                elevation: 0.5,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$jumlah",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    barang.namaBarang,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    formatCurrency(barang.hargaJual),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  trailing: SizedBox(
                                    width: 160,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Quantity Controls
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                                          onPressed: () {
                                            _ubahJumlah(index, -1);
                                            setModalState(() {});
                                            if (_cart.isEmpty) Navigator.pop(context);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                                          onPressed: () {
                                            _ubahJumlah(index, 1);
                                            setModalState(() {});
                                          },
                                        ),
                                        
                                        const Spacer(),
                                        
                                        // Subtotal & Delete
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatCurrency(subtotal),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                          onPressed: () {
                                            _hapusDariCart(index);
                                            setModalState(() {});
                                            if (_cart.isEmpty) Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Checkout Section in Bottom Sheet
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
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
                              const Text("Total Pembayaran", style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(
                                formatCurrency(_totalHarga),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _cart.isEmpty ? null : () {
                              Navigator.pop(context); // Close bottom sheet
                              _bayar(); // Call pay function
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "BAYAR",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Dialog Pembayaran
class _PembayaranDialog extends StatefulWidget {
  final int totalHarga;

  const _PembayaranDialog({required this.totalHarga});

  @override
  State<_PembayaranDialog> createState() => _PembayaranDialogState();
}

class _PembayaranDialogState extends State<_PembayaranDialog> {
  final TextEditingController _bayarController = TextEditingController();
  int _kembalian = 0;

  @override
  void initState() {
    super.initState();
    _bayarController.text = widget.totalHarga.toString();
    _hitHittKembalian();
  }

  void _hitHittKembalian() {
    final bayar = int.tryParse(_bayarController.text) ?? 0;
    setState(() {
      _kembalian = bayar - widget.totalHarga;
    });
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pembayaran"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Total: ${formatCurrency(widget.totalHarga)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bayarController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Jumlah Bayar",
              border: OutlineInputBorder(),
              prefixText: "Rp ",
            ),
            onChanged: (value) => _hitHittKembalian(),
          ),
          const SizedBox(height: 16),
          Text(
            "Kembalian: ${formatCurrency(_kembalian)}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kembalian >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: _kembalian >= 0
              ? () {
                  final bayar = int.tryParse(_bayarController.text) ?? 0;
                  Navigator.pop(context, {
                    'bayar': bayar,
                    'kembalian': _kembalian,
                  });
                }
              : null,
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}

