import 'package:flutter/material.dart';
import 'package:kasirku/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: [_usernameController.text, _passwordController.text],
    );

    if (result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('idUser', result.first['id_user'] as int); // ✅ Save user ID
      await prefs.setString('namaUser', result.first['nama_user'].toString());
      await prefs.setString('role', result.first['role'].toString());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()), // ✅ ke Home
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username atau password salah")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "LOGIN KASIR",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}