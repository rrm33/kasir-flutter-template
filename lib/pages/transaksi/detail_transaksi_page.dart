import 'package:flutter/material.dart';
import 'package:kasirku/database/database_helper.dart';
import 'package:kasirku/models/transaksi.dart';
import 'package:kasirku/models/detail_transaksi.dart';
import 'package:kasirku/pages/transaksi/struk_page.dart';
import 'package:kasirku/services/telegram_service.dart';
import 'package:intl/intl.dart';

class DetailTransaksiPage extends StatefulWidget {
  final Transaksi transaksi;

  const DetailTransaksiPage({super.key, required this.transaksi});

  @override
  State<DetailTransaksiPage> createState() => _DetailTransaksiPageState();
}

class _DetailTransaksiPageState extends State<DetailTransaksiPage> {
  List<DetailTransaksi> _details = [];
  Map<int, String> _namaBarang = {};
  String _namaKasir = "Unknown";
  String _status = "SUKSES";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await DatabaseHelper.instance.getDetailByTransaksi(
      widget.transaksi.idTransaksi!,
    );

    // Load nama barang untuk setiap detail
    Map<int, String> namaBarangMap = {};
    for (var detail in details) {
      final barang = await DatabaseHelper.instance.getAllBarang();
      final found = barang.where((b) => b.idBarang == detail.idBarang).firstOrNull;
      if (found != null) {
        namaBarangMap[detail.idBarang] = found.namaBarang;
      }
    }

    // Fetch user name
    final user = await DatabaseHelper.instance.getAllUser().then((users) => 
        users.where((u) => u.idUser == widget.transaksi.idKasir).firstOrNull);

    setState(() {
      _details = details;
      _namaBarang = namaBarangMap;
      if (user != null) {
        _namaKasir = user.namaUser;
      }
      _status = widget.transaksi.status;
      isLoading = false;
    });
  }

  Future<void> _voidTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Void"),
        content: const Text("Apakah Anda yakin ingin membatalkan transaksi ini? Stok barang akan dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await DatabaseHelper.instance.voidTransaksi(widget.transaksi.idTransaksi!);
        
        // Kirim Notifikasi Telegram
        final db = DatabaseHelper.instance;
        final toko = await db.getToko();
        if (toko != null) {
          final double totalOmset = await db.getTotalOmset();
          await TelegramService.sendVoidNotification(
            namaKasir: _namaKasir,
            transaksi: widget.transaksi,
            saldoSetelah: totalOmset,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaksi berhasil dibatalkan"), backgroundColor: Colors.orange),
        );
        
        setState(() {
          _status = "VOID";
          isLoading = false;
        });
        
        // Navigator.pop(context, true) tidak langsung dipanggil agar user bisa lihat status "VOID" di halaman ini
        // Tapi kita kasih delay atau simpan flag agar saat user back nanti list transaksi ter-refresh
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membatalkan transaksi: $e"), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
      }
    }
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String formatTanggal(String tgl) {
    try {
      final date = DateTime.parse(tgl);
      return DateFormat('dd-MM-yyyy HH:mm', 'id_ID').format(date);
    } catch (e) {
      return tgl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.transaksi.nomorTransaksi ?? "Detail Transaksi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _status == "VOID"),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Cetak Struk",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StrukPage(idTransaksi: widget.transaksi.idTransaksi!),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info Transaksi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total: ${formatCurrency(widget.transaksi.totalHarga)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tanggal: ${formatTanggal(widget.transaksi.tglTransaksi)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Kasir: $_namaKasir",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bayar: ${formatCurrency(widget.transaksi.bayar)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Kembalian: ${formatCurrency(widget.transaksi.kembalian)}",
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List Item
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Item Purchased",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: _details.isEmpty
                      ? const Center(child: Text("Tidak ada detail"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _details.length,
                          itemBuilder: (context, index) {
                            final detail = _details[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withAlpha(25),
                                  child: Text(
                                    "${detail.jumlah}x",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _namaBarang[detail.idBarang] ?? "Barang ID: ${detail.idBarang}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${formatCurrency(detail.hargaAtTime.toDouble())} x ${detail.jumlah}",
                                ),
                                trailing: Text(
                                  formatCurrency(detail.subtotal.toDouble()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                if (_status == 'SUKSES')
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _voidTransaction,
                        icon: const Icon(Icons.cancel),
                        label: const Text("Batalkan Transaksi (VOID)", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "TRANSAKSI SUDAH DIBATALKAN (VOID)",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

