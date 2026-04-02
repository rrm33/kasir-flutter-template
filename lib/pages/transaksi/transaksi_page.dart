import 'package:flutter/material.dart';
import 'package:kasirku/database/database_helper.dart';
import 'package:kasirku/models/transaksi.dart';
import 'package:intl/intl.dart';
import 'detail_transaksi_page.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {

  List<Transaksi> listTransaksi = [];
  Map<int, String> mapNamaKasir = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      listTransaksi = await DatabaseHelper.instance.getAllTransaksi();
      
      // Fetch names
      Map<int, String> names = {};
      final users = await DatabaseHelper.instance.getAllUser();
      for (var u in users) {
        if (u.idUser != null) {
          names[u.idUser!] = u.namaUser;
        }
      }

      if (mounted) {
        setState(() {
          mapNamaKasir = names;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Error: ${e.toString()}";
        });
      }
    }
  }

  Future<void> delete(int id) async {
    try {
      // Hapus detail dulu, baru hapus transaksi
      await DatabaseHelper.instance.deleteDetailTransaksi(id);
      await DatabaseHelper.instance.deleteTransaksi(id);
      await loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
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
        title: const Text("Data Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadData,
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                )
              : listTransaksi.isEmpty
                  ? const Center(child: Text("Belum ada transaksi"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listTransaksi.length,
                      itemBuilder: (context, index) {
                        final trx = listTransaksi[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailTransaksiPage(transaksi: trx),
                                ),
                              ).then((val) {
                                if (val == true) loadData();
                              });
                            },
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Text(
                                  formatCurrency(trx.totalHarga),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    decoration: trx.status == 'VOID' ? TextDecoration.lineThrough : null,
                                    color: trx.status == 'VOID' ? Colors.orange : Colors.black,
                                  ),
                                ),
                                if (trx.status == 'VOID')
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "VOID",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trx.nomorTransaksi ?? "#${trx.idTransaksi}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                                ),
                                const SizedBox(height: 4),
                                Text("Kasir: ${mapNamaKasir[trx.idKasir] ?? trx.idKasir}"),
                                Text(formatTanggal(trx.tglTransaksi)),
                                Text("Bayar: ${formatCurrency(trx.bayar)} | Kembalian: ${formatCurrency(trx.kembalian)}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.green),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailTransaksiPage(transaksi: trx),
                                      ),
                                    ).then((val) {
                                      if (val == true) loadData();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Hapus Transaksi"),
                                        content: const Text("Yakin ingin menghapus transaksi ini?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("Batal"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              delete(trx.idTransaksi!);
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
