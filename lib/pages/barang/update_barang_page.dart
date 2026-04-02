import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../database/database_helper.dart';
import '../../models/barang.dart';

class UpdateBarangPage extends StatefulWidget {
  final Barang barang;

  const UpdateBarangPage({super.key, required this.barang});

  @override
  State<UpdateBarangPage> createState() => _UpdateBarangPageState();
}

class _UpdateBarangPageState extends State<UpdateBarangPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController kodeController;
  late TextEditingController namaController;
  late TextEditingController hargaBeliController;
  late TextEditingController hargaJualController;
  late TextEditingController stokController;
  late TextEditingController kategoriController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    kodeController =
        TextEditingController(text: widget.barang.kodeBarcode);
    namaController =
        TextEditingController(text: widget.barang.namaBarang);
    hargaBeliController =
        TextEditingController(text: widget.barang.hargaBeli.toString());
    hargaJualController =
        TextEditingController(text: widget.barang.hargaJual.toString());
    stokController =
        TextEditingController(text: widget.barang.stok.toString());
    kategoriController =
        TextEditingController(text: widget.barang.kategori ?? "");
        
    if (widget.barang.foto != null) {
      _selectedImage = File(widget.barang.foto!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBarang() async {
    if (_formKey.currentState!.validate()) {
      final barangUpdate = Barang(
        idBarang: widget.barang.idBarang,
        kodeBarcode: kodeController.text,
        namaBarang: namaController.text,
        hargaBeli: int.parse(hargaBeliController.text),
        hargaJual: int.parse(hargaJualController.text),
        stok: int.parse(stokController.text),
        foto: _selectedImage?.path,
        kategori: kategoriController.text,
      );

      await DatabaseHelper.instance.updateBarang(barangUpdate);

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Barang")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Pilih Foto Barang", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: kodeController,
                readOnly: true,
                decoration:
                    const InputDecoration(labelText: "Kode Barcode"),
              ),
              TextFormField(
                controller: namaController,
                decoration:
                    const InputDecoration(labelText: "Nama Barang"),
                validator: (value) =>
                    value!.isEmpty ? "Tidak boleh kosong" : null,
              ),
              TextFormField(
                controller: hargaBeliController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Harga Beli"),
                validator: (value) =>
                    value!.isEmpty ? "Tidak boleh kosong" : null,
              ),
              TextFormField(
                controller: hargaJualController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Harga Jual"),
                validator: (value) =>
                    value!.isEmpty ? "Tidak boleh kosong" : null,
              ),
              TextFormField(
                controller: stokController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Stok"),
                validator: (value) =>
                    value!.isEmpty ? "Tidak boleh kosong" : null,
              ),
              TextFormField(
                controller: kategoriController,
                decoration:
                    const InputDecoration(labelText: "Kategori (Opsional)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateBarang,
                child: const Text("Update"),
              )
            ],
          ),
        ),
      ),
    );
  }
}