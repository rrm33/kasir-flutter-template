import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasirku/database/database_helper.dart';
import 'package:kasirku/models/toko.dart';

class TokoSettingsPage extends StatefulWidget {
  const TokoSettingsPage({Key? key}) : super(key: key);

  @override
  State<TokoSettingsPage> createState() => _TokoSettingsPageState();
}

class _TokoSettingsPageState extends State<TokoSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _sloganController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _webController = TextEditingController();
  
  String? _logoPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokoData();
  }

  Future<void> _loadTokoData() async {
    final toko = await DatabaseHelper.instance.getToko();
    if (toko != null) {
      setState(() {
        _namaController.text = toko.namaToko;
        _sloganController.text = toko.slogan ?? '';
        _alamatController.text = toko.alamat ?? '';
        _teleponController.text = toko.telepon ?? '';
        _tiktokController.text = toko.tiktok ?? '';
        _instagramController.text = toko.instagram ?? '';
        _facebookController.text = toko.facebook ?? '';
        _webController.text = toko.web ?? '';
        _logoPath = toko.logo;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final toko = Toko(
        namaToko: _namaController.text,
        slogan: _sloganController.text,
        alamat: _alamatController.text,
        telepon: _teleponController.text,
        logo: _logoPath,
        tiktok: _tiktokController.text,
        instagram: _instagramController.text,
        facebook: _facebookController.text,
        web: _webController.text,
      );

      await DatabaseHelper.instance.saveToko(toko);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan toko berhasil disimpan')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Toko'),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(60),
                      image: _logoPath != null
                          ? DecorationImage(
                              image: FileImage(File(_logoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _logoPath == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const Center(child: Text('Ketuk untuk unggah logo', style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 24),

              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama toko wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _sloganController,
                decoration: const InputDecoration(
                  labelText: 'Slogan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _teleponController,
                decoration: const InputDecoration(
                  labelText: 'Telepon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Media Sosial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _tiktokController,
                decoration: const InputDecoration(
                  labelText: 'TikTok',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.camera_alt),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.facebook),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _webController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Pengaturan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
