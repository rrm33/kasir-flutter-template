import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../database/database_helper.dart';
import 'tambah_user_page.dart';
import 'update_user_page.dart';


class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<User> listUser = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await DatabaseHelper.instance.getAllUser();
    setState(() {
      listUser = data;
    });
  }

  Future<void> _deleteUser(int id) async {
    await DatabaseHelper.instance.deleteUser(id);
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data User"),
      ),
      body: listUser.isEmpty
          ? const Center(
              child: Text("Belum ada user"),
            )
          : ListView.builder(
              itemCount: listUser.length,
              itemBuilder: (context, index) {
                final user = listUser[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(user.namaUser),
                    subtitle: Text(
                        "${user.username} • Role: ${user.role}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UpdateUserPage(user: user),
                              ),
                            );

                            if (result == true) {
                              _loadUser();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteUser(user.idUser!);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahUserPage(),
            ),
          );

          if (result == true) {
            _loadUser();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}