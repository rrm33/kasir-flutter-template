import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart';

class TambahUserPage extends StatefulWidget {
  const TambahUserPage({Key? key}) : super(key: key);

  @override
  State<TambahUserPage> createState() => _TambahUserPageState();
}

class _TambahUserPageState extends State<TambahUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = "kasir";

  Future<void> _simpanUser() async {
    if (_formKey.currentState!.validate()) {
      User user = User(
        namaUser: _namaController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      await DatabaseHelper.instance.insertUser(user);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah User"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // Nama
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: "Nama User",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Nama tidak boleh kosong";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Username tidak boleh kosong";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password tidak boleh kosong";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "kasir",
                    child: Text("Kasir"),
                  ),
                  DropdownMenuItem(
                    value: "admin",
                    child: Text("Admin"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _simpanUser,
                child: const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}