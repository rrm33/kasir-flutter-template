class Transaksi {
  int? idTransaksi;
  String? nomorTransaksi;
  int idToko;
  int idKasir;
  String tglTransaksi;
  double totalHarga;
  double bayar;
  double kembalian;
  String status; // 'SUKSES' atau 'VOID'

  Transaksi({
    this.idTransaksi,
    this.nomorTransaksi,
    required this.idToko,
    required this.idKasir,
    required this.tglTransaksi,
    required this.totalHarga,
    required this.bayar,
    required this.kembalian,
    this.status = 'SUKSES',
  });

  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': idTransaksi,
      'nomor_transaksi': nomorTransaksi,
      'id_toko': idToko,
      'id_kasir': idKasir,
      'tgl_transaksi': tglTransaksi,
      'total_harga': totalHarga,
      'bayar': bayar,
      'kembalian': kembalian,
      'status': status,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      idTransaksi: map['id_transaksi'],
      nomorTransaksi: map['nomor_transaksi'],
      idToko: map['id_toko'],
      idKasir: map['id_kasir'],
      tglTransaksi: map['tgl_transaksi'],
      totalHarga: (map['total_harga'] as num).toDouble(),
      bayar: (map['bayar'] as num).toDouble(),
      kembalian: (map['kembalian'] as num).toDouble(),
      status: map['status'] ?? 'SUKSES',
    );
  }
}