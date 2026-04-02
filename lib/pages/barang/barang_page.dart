import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kasirku/pages/barang/tambah_barang_page.dart';
import '../../database/database_helper.dart';
import '../../models/barang.dart';
import 'update_barang_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  List<Barang> _allBarang = [];
  List<Barang> _filteredBarang = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  void _loadBarang() async {
    final data = await DatabaseHelper.instance.getAllBarang();
    setState(() {
      _allBarang = data;
      _filteredBarang = data;
    });
  }

  void _filterBarang(String query) {
    setState(() {
      _filteredBarang = _allBarang
          .where((item) =>
              item.namaBarang.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Barang"),
        content: const Text("Yakin ingin menghapus barang ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteBarang(id);
              if (!mounted) return;
              Navigator.pop(context);
              _loadBarang();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Inventori Barang", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeaderSummary(),
          _buildSearchBar(),
          Expanded(
            child: _filteredBarang.isEmpty
                ? const Center(child: Text("Barang tidak ditemukan"))
                : _buildGridBarang(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahBarangPage()),
          );
          if (result == true) _loadBarang();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Widget Ringkasan Total Barang
  Widget _buildHeaderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Total Jenis", _allBarang.length.toString()),
          _summaryItem("Total Stok", _allBarang.fold(0, (sum, item) => sum + (item.stok)).toString()),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Widget Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _filterBarang,
        decoration: InputDecoration(
          hintText: "Cari nama barang...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Widget Grid Layout ala POS
  Widget _buildGridBarang() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 kolom
        childAspectRatio: 0.9, // Disesuaikan agar lebih pendek
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredBarang.length,
      itemBuilder: (context, index) {
        final item = _filteredBarang[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Atas: Info Stok
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item.stok) < 5 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: (item.stok) < 5 ? Colors.red : Colors.blue),
                    Text("Stok: ${item.stok}", style: TextStyle(fontWeight: FontWeight.bold, color: (item.stok) < 5 ? Colors.red : Colors.blue)),
                  ],
                ),
              ),
              // Isi Card
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Barang
                    Expanded(
                      child: GestureDetector(
                        onTap: item.foto != null
                            ? () => _showImagePreview(context, item.foto!, 'preview_${item.idBarang}')
                            : null,
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: item.foto != null
                              ? Hero(
                                  tag: 'preview_${item.idBarang}',
                                  child: Image.file(
                                    File(item.foto!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image_not_supported,
                                  size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (item.kategori != null && item.kategori!.isNotEmpty)
                            Text(item.kategori!, style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontStyle: FontStyle.italic)),
                          Text("Rp ${item.hargaJual}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                          // Tombol Aksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => UpdateBarangPage(barang: item)),
                                  );
                                  if (result == true) _loadBarang();
                                },
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _confirmDelete(item.idBarang!),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}