class Barang {
  final int? idBarang;
  final String kodeBarcode;
  final String namaBarang;
  final int hargaBeli;
  final int hargaJual;
  final int stok;
  final String? foto;
  final String? kategori;

  Barang({
    this.idBarang,
    required this.kodeBarcode,
    required this.namaBarang,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
    this.foto,
    this.kategori,
  });

  /// Convert object ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'id_barang': idBarang,
      'kode_barcode': kodeBarcode,
      'nama_barang': namaBarang,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok': stok,
      'foto': foto,
      'kategori': kategori,
    };
  }

  /// Convert Map dari database ke object
  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      idBarang: map['id_barang'] as int?,
      kodeBarcode: map['kode_barcode'] as String,
      namaBarang: map['nama_barang'] as String,
      hargaBeli: map['harga_beli'] as int,
      hargaJual: map['harga_jual'] as int,
      stok: map['stok'] as int,
      foto: map['foto'] as String?,
      kategori: map['kategori'] as String?,
    );
  }
}