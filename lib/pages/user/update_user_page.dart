import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart';

class UpdateUserPage extends StatefulWidget {
  final User user;

  const UpdateUserPage({Key? key, required this.user}) : super(key: key);

  @override
  State<UpdateUserPage> createState() => _UpdateUserPageState();
}

class _UpdateUserPageState extends State<UpdateUserPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  late String _selectedRole;

  @override
  void initState() {
    super.initState();

    _namaController =
        TextEditingController(text: widget.user.namaUser);
    _usernameController =
        TextEditingController(text: widget.user.username);
    _passwordController =
        TextEditingController(text: widget.user.password);

    _selectedRole = widget.user.role;
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      User updatedUser = User(
        idUser: widget.user.idUser,
        namaUser: _namaController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update User"),
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

              // Role
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
                onPressed: _updateUser,
                child: const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}