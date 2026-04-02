import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kasirku/database/database_helper.dart';
import 'package:kasirku/models/transaksi.dart';
import 'package:kasirku/models/detail_transaksi.dart';
import 'package:kasirku/models/user.dart';
import 'package:kasirku/models/toko.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StrukPage extends StatefulWidget {
  final int idTransaksi;

  const StrukPage({super.key, required this.idTransaksi});

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  Transaksi? _transaksi;
  List<DetailTransaksi> _details = [];
  Map<int, String> _namaBarang = {};
  User? _kasir;
  Toko? _shop;
  bool isLoading = true;

  // Screenshot Controller
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final transaksi = await db.getTransaksiById(widget.idTransaksi);
    
    if (transaksi == null) {
      setState(() => isLoading = false);
      return;
    }

    final shop = await db.getToko();

    final details = await db.getDetailByTransaksi(transaksi.idTransaksi!);
    final kasir = await db.getAllUser().then((users) => 
        users.where((u) => u.idUser == transaksi.idKasir).firstOrNull);

    Map<int, String> namaBarangMap = {};
    for (var detail in details) {
      final barangAll = await db.getAllBarang();
      final found = barangAll.where((b) => b.idBarang == detail.idBarang).firstOrNull;
      if (found != null) {
        namaBarangMap[detail.idBarang] = found.namaBarang;
      }
    }

    setState(() {
      _transaksi = transaksi;
      _details = details;
      _kasir = kasir;
      _namaBarang = namaBarangMap;
      _shop = shop;
      isLoading = false;
    });
  }

  Future<void> _printStruk() async {
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image == null) return;

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          final pwImage = pw.MemoryImage(image);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.roll57, // Standard thermal paper width
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(pwImage),
                );
              },
            ),
          );

          return pdf.save();
        },
        name: 'Struk_${_transaksi!.nomorTransaksi ?? _transaksi!.idTransaksi}',
      );
    } catch (e) {
      _showSnackBar("Gagal mencetak: $e", Colors.red);
    }
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String formatTanggal(String tgl) {
    try {
      final date = DateTime.parse(tgl);
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
    } catch (e) {
      return tgl;
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  Future<void> _shareStruk() async {
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/struk_${_transaksi!.idTransaksi}.png').create();
        await imagePath.writeAsBytes(image);

        final xFile = XFile(imagePath.path);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          text: 'Struk Transaksi KasirKu ${_transaksi!.nomorTransaksi ?? "#"+_transaksi!.idTransaksi.toString()}',
        );
      } else {
        _showSnackBar("Gagal mengambil gambar struk", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Gagal membagikan struk: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_transaksi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Struk")),
        body: const Center(child: Text("Transaksi tidak ditemukan")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Preview Struk", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: 320, // Standard receipt paper width approximation
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_shop?.logo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(_shop!.logo!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black87, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                "K",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          _shop?.namaToko.toUpperCase() ?? "KASIRKU",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        if (_shop?.slogan != null && _shop!.slogan!.isNotEmpty)
                          Text(
                            _shop!.slogan!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        if (_shop?.telepon != null && _shop!.telepon!.isNotEmpty)
                          Text(
                            "Telp: ${_shop!.telepon}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 16),
                        // Meta Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tanggal:", style: TextStyle(fontSize: 12)),
                            Text(formatTanggal(_transaksi!.tglTransaksi), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Kasir:", style: TextStyle(fontSize: 12)),
                            Text(_kasir?.namaUser ?? "Unknown", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("No. Trx:", style: TextStyle(fontSize: 12)),
                            Text(_transaksi!.nomorTransaksi ?? _transaksi!.idTransaksi.toString(), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const Divider(thickness: 1, height: 24, color: Colors.black87),
                        
                        // Items
                        ..._details.map((detail) {
                          final nama = _namaBarang[detail.idBarang] ?? "Barang";
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${detail.jumlah} x ${formatCurrency(detail.hargaAtTime.toDouble())}"),
                                    Text(formatCurrency(detail.subtotal.toDouble())),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        const Divider(thickness: 1, height: 24, color: Colors.black87),
                        
                        // Totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL LAPORAN", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatCurrency(_transaksi!.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("BAYAR"),
                            Text(formatCurrency(_transaksi!.bayar)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("KEMBALIAN"),
                            Text(formatCurrency(_transaksi!.kembalian)),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        const Text(
                          "Terima Kasih Atas Kunjungan Anda",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        
                        if (_shop != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            children: [
                              if (_shop!.instagram != null && _shop!.instagram!.isNotEmpty)
                                _medsosIcon(Icons.camera_alt, _shop!.instagram!),
                              if (_shop!.tiktok != null && _shop!.tiktok!.isNotEmpty)
                                _medsosIcon(Icons.music_note, _shop!.tiktok!),
                              if (_shop!.facebook != null && _shop!.facebook!.isNotEmpty)
                                _medsosIcon(Icons.facebook, _shop!.facebook!),
                              if (_shop!.web != null && _shop!.web!.isNotEmpty)
                                _medsosIcon(Icons.language, _shop!.web!),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Text(
                          "Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.blueAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _shareStruk,
                      icon: const Icon(Icons.share),
                      label: const Text("BAGIKAN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _printStruk,
                      icon: const Icon(Icons.print),
                      label: const Text("CETAK"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medsosIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      ],
    );
  }
}
