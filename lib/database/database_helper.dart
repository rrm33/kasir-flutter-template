import 'package:kasirku/models/transaksi.dart';
import 'package:kasirku/models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/barang.dart';
import '../models/detail_transaksi.dart';
import '../models/toko.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 7, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE BARANG ADD COLUMN foto TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE TRANSAKSI ADD COLUMN nomor_transaksi TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE TOKO ADD COLUMN slogan TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN logo TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN tiktok TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN instagram TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN facebook TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN web TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE BARANG ADD COLUMN kategori TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE TOKO ADD COLUMN telegram_token TEXT');
      await db.execute('ALTER TABLE TOKO ADD COLUMN telegram_chat_id TEXT');
    }
    if (oldVersion < 7) {
      // Pastikan kolom status belum ada sebelum menambahkannya
      var results = await db.rawQuery("PRAGMA table_info(TRANSAKSI)");
      bool hasStatus = results.any((column) => column['name'] == 'status');
      if (!hasStatus) {
        await db.execute("ALTER TABLE TRANSAKSI ADD COLUMN status TEXT DEFAULT 'SUKSES'");
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE TOKO(
      id_toko INTEGER PRIMARY KEY AUTOINCREMENT,
      nama_toko TEXT,
      alamat TEXT,
      telepon TEXT,
      slogan TEXT,
      logo TEXT,
      tiktok TEXT,
      instagram TEXT,
      facebook TEXT,
      web TEXT,
      telegram_token TEXT,
      telegram_chat_id TEXT
    )
    ''');

    await db.execute('''
CREATE TABLE user(
  id_user INTEGER PRIMARY KEY AUTOINCREMENT,
  nama_user TEXT,
  username TEXT UNIQUE,
  password TEXT,
  role TEXT
)
''');

    await db.insert('user', {
      'nama_user': 'Administrator',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    await db.execute('''
    CREATE TABLE BARANG(
      id_barang INTEGER PRIMARY KEY AUTOINCREMENT,
      kode_barcode TEXT,
      nama_barang TEXT,
      harga_beli INTEGER,
      harga_jual INTEGER,
      stok INTEGER,
      foto TEXT,
      kategori TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE TRANSAKSI(
      id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT,
      nomor_transaksi TEXT,
      id_toko INTEGER,
      id_kasir INTEGER,
      tgl_transaksi TEXT,
      total_harga INTEGER,
      bayar INTEGER,
      kembalian INTEGER,
      status TEXT DEFAULT 'SUKSES'
    )
    ''');

    await db.execute('''
    CREATE TABLE DETAIL_TRANSAKSI(
      id_detail INTEGER PRIMARY KEY AUTOINCREMENT,
      id_transaksi INTEGER,
      id_barang INTEGER,
      jumlah INTEGER,
      harga_at_time INTEGER,
      subtotal INTEGER
    )
    ''');
  }

  Future<void> testInsert() async {
    final db = await instance.database;

    await db.insert('TOKO', {
      'nama_toko': 'Toko Rejeki Mengalir',
      'alamat': 'Tanggul, Jember',
      'telepon': '08123456789',
    });

    print("Insert TOKO berhasil");
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // CRUD BARANG //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<int> insertBarang(Barang barang) async {
    final db = await instance.database;

    return await db.insert('BARANG', barang.toMap());
  }

  Future<List<Barang>> getAllBarang() async {
    final db = await instance.database;

    final result = await db.query('BARANG', orderBy: 'nama_barang ASC');

    return result.map((map) => Barang.fromMap(map)).toList();
  }

  Future<int> deleteBarang(int id) async {
    final db = await instance.database;

    return await db.delete('BARANG', where: 'id_barang = ?', whereArgs: [id]);
  }

  Future<int> updateBarang(Barang barang) async {
    final db = await instance.database;

    return await db.update(
      'BARANG',
      barang.toMap(),
      where: 'id_barang = ?',
      whereArgs: [barang.idBarang],
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // CRUD USER //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('user', user.toMap());
  }

  Future<List<User>> getAllUser() async {
    final db = await database;
    final result = await db.query('user');

    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('user', where: 'id_user = ?', whereArgs: [id]);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id_user = ?',
      whereArgs: [user.idUser],
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // CRUD TRANSAKSI //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<String> generateNomorTransaksi() async {
    final db = await database;
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final prefix = "KS$year$month";

    // Check transactions this month
    final result = await db.query(
      'transaksi',
      columns: ['nomor_transaksi'],
      where: "nomor_transaksi LIKE ?",
      whereArgs: ["$prefix%"],
      orderBy: "id_transaksi DESC",
      limit: 1,
    );

    if (result.isNotEmpty && result.first['nomor_transaksi'] != null) {
      final lastNomor = result.first['nomor_transaksi'] as String;
      if (lastNomor.length >= 12) {
        final lastNumberStr = lastNomor.substring(8);
        final lastNumber = int.tryParse(lastNumberStr) ?? 0;
        final nextNumber = (lastNumber + 1).toString().padLeft(4, '0');
        return "$prefix$nextNumber";
      }
    }

    return "${prefix}0001";
  }

  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final result = await db.query('transaksi', orderBy: 'tgl_transaksi DESC');

    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await database;

    return await db.update(
      'transaksi',
      transaksi.toMap(),
      where: 'id_transaksi=?',
      whereArgs: [transaksi.idTransaksi],
    );
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await database;

    return await db.delete(
      'transaksi',
      where: 'id_transaksi=?',
      whereArgs: [id],
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // CRUD DETAIL TRANSAKSI //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<int> insertDetailTransaksi(DetailTransaksi detail) async {
    final db = await database;
    return await db.insert('detail_transaksi', detail.toMap());
  }

  Future<List<DetailTransaksi>> getDetailByTransaksi(int idTransaksi) async {
    final db = await database;
    final result = await db.query(
      'detail_transaksi',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
    return result.map((e) => DetailTransaksi.fromMap(e)).toList();
  }

  Future<int> deleteDetailTransaksi(int idTransaksi) async {
    final db = await database;
    return await db.delete(
      'detail_transaksi',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
  }

  // Get barang by barcode (untuk kasir scan)
  Future<Barang?> getBarangByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'BARANG',
      where: 'kode_barcode = ?',
      whereArgs: [barcode],
    );
    if (result.isEmpty) return null;
    return Barang.fromMap(result.first);
  }

  // Update stok barang (kurangi saat transaksi)
  Future<int> updateStokBarang(int idBarang, int newStok) async {
    final db = await database;
    return await db.update(
      'BARANG',
      {'stok': newStok},
      where: 'id_barang = ?',
      whereArgs: [idBarang],
    );
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'user',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<Transaksi?> getTransaksiById(int id) async {
    final db = await database;
    final result = await db.query(
      'transaksi',
      where: 'id_transaksi = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Transaksi.fromMap(result.first);
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // CRUD TOKO //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<Toko?> getToko() async {
    final db = await database;
    final result = await db.query('TOKO', limit: 1);
    if (result.isEmpty) return null;
    return Toko.fromMap(result.first);
  }

  Future<int> insertToko(Toko toko) async {
    final db = await database;
    return await db.insert('TOKO', toko.toMap());
  }

  Future<int> updateToko(Toko toko) async {
    final db = await database;
    return await db.update(
      'TOKO',
      toko.toMap(),
      where: 'id_toko = ?',
      whereArgs: [toko.idToko],
    );
  }

  Future<int> saveToko(Toko toko) async {
    final existing = await getToko();
    if (existing == null) {
      return await insertToko(toko);
    } else {
      // Create a new Toko object with the existing id to perform update
      final toUpdate = Toko(
        idToko: existing.idToko,
        namaToko: toko.namaToko,
        slogan: toko.slogan,
        alamat: toko.alamat,
        telepon: toko.telepon,
        logo: toko.logo,
        tiktok: toko.tiktok,
        instagram: toko.instagram,
        facebook: toko.facebook,
        web: toko.web,
      );
      return await updateToko(toUpdate);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////
  // REPORT QUERIES //
  ////////////////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> getReportSummary(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Total Transaksi, Total Omset, Total Bayar
    final result = await db.rawQuery('''
      SELECT 
        COUNT(id_transaksi) as total_transaksi,
        SUM(total_harga) as total_omset,
        SUM(bayar) as total_bayar
      FROM TRANSAKSI
      WHERE tgl_transaksi BETWEEN ? AND ? AND IFNULL(status, 'SUKSES') = 'SUKSES'
    ''', [startStr, endStr]);

    // Total Modal & Profit
    // Profit = Total Harga Jual - Total Harga Beli (saat itu)
    final profitResult = await db.rawQuery('''
      SELECT 
        SUM(dt.jumlah * b.harga_beli) as total_modal,
        SUM(dt.subtotal) as total_pendapatan
      FROM DETAIL_TRANSAKSI dt
      JOIN TRANSAKSI t ON dt.id_transaksi = t.id_transaksi
      JOIN BARANG b ON dt.id_barang = b.id_barang
      WHERE t.tgl_transaksi BETWEEN ? AND ? AND IFNULL(t.status, 'SUKSES') = 'SUKSES'
    ''', [startStr, endStr]);

    final totalTransaksi = result.first['total_transaksi'] as int? ?? 0;
    final totalOmset = (result.first['total_omset'] as num?)?.toDouble() ?? 0.0;
    final totalModal = (profitResult.first['total_modal'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = totalOmset - totalModal;

    return {
      'total_transaksi': totalTransaksi,
      'total_omset': totalOmset,
      'total_modal': totalModal,
      'total_profit': totalProfit,
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryStats(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    return await db.rawQuery('''
      SELECT 
        IFNULL(b.kategori, 'Tanpa Kategori') as kategori,
        SUM(dt.jumlah) as total_qty,
        SUM(dt.subtotal) as total_omset
      FROM DETAIL_TRANSAKSI dt
      JOIN TRANSAKSI t ON dt.id_transaksi = t.id_transaksi
      LEFT JOIN BARANG b ON dt.id_barang = b.id_barang
      WHERE t.tgl_transaksi BETWEEN ? AND ? AND IFNULL(t.status, 'SUKSES') = 'SUKSES'
      GROUP BY kategori
      ORDER BY total_omset DESC
    ''', [startStr, endStr]);
  }

  Future<List<Map<String, dynamic>>> getBestSellingItems(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    return await db.rawQuery('''
      SELECT 
        b.nama_barang,
        SUM(dt.jumlah) as total_qty,
        SUM(dt.subtotal) as total_omset
      FROM DETAIL_TRANSAKSI dt
      JOIN TRANSAKSI t ON dt.id_transaksi = t.id_transaksi
      JOIN BARANG b ON dt.id_barang = b.id_barang
      WHERE t.tgl_transaksi BETWEEN ? AND ? AND IFNULL(t.status, 'SUKSES') = 'SUKSES'
      GROUP BY b.id_barang
      ORDER BY total_qty DESC
      LIMIT 10
    ''', [startStr, endStr]);
  }

  Future<double> getTotalOmset() async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(total_harga) as total FROM TRANSAKSI WHERE IFNULL(status, 'SUKSES') = 'SUKSES'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> voidTransaksi(int idTransaksi) async {
    final db = await database;

    // 1. Cek apakah sudah Void sebelumnya untuk mencegah double restock
    final check = await db.query(
      'TRANSAKSI',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );

    if (check.isNotEmpty && check.first['status'] == 'VOID') {
      throw Exception("Transaksi ini sudah dibatalkan sebelumnya.");
    }

    // 2. Ambil detail transaksi untuk restock
    final details = await db.query(
      'DETAIL_TRANSAKSI',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );

    await db.transaction((txn) async {
      // 3. Update status transaksi jadi VOID
      await txn.update(
        'TRANSAKSI',
        {'status': 'VOID'},
        where: 'id_transaksi = ?',
        whereArgs: [idTransaksi],
      );

      // 4. Kembalikan stok untuk setiap item
      for (var detail in details) {
        final idBarang = detail['id_barang'];
        final jumlah = detail['jumlah'];

        await txn.rawUpdate(
          'UPDATE BARANG SET stok = stok + ? WHERE id_barang = ?',
          [jumlah, idBarang],
        );
      }
    });
  }
}
