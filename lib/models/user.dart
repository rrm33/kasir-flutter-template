class User {
  int? idUser;
  String namaUser;
  String username;
  String password;
  String role;

  User({
    this.idUser,
    required this.namaUser,
    required this.username,
    required this.password,
    required this.role,
  });

  // Convert object ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama_user': namaUser,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  // Convert Map ke object (ambil dari database)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      idUser: map['id_user'] as int?,
      namaUser: map['nama_user'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
    );
  }
}