class DetailTransaksi {
  int? idDetail;
  int idTransaksi;
  int idBarang;
  int jumlah;
  int hargaAtTime;
  int subtotal;

  DetailTransaksi({
    this.idDetail,
    required this.idTransaksi,
    required this.idBarang,
    required this.jumlah,
    required this.hargaAtTime,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_detail': idDetail,
      'id_transaksi': idTransaksi,
      'id_barang': idBarang,
      'jumlah': jumlah,
      'harga_at_time': hargaAtTime,
      'subtotal': subtotal,
    };
  }

  factory DetailTransaksi.fromMap(Map<String, dynamic> map) {
    return DetailTransaksi(
      idDetail: map['id_detail'] as int?,
      idTransaksi: map['id_transaksi'] as int,
      idBarang: map['id_barang'] as int,
      jumlah: map['jumlah'] as int,
      hargaAtTime: map['harga_at_time'] as int,
      subtotal: map['subtotal'] as int,
    );
  }
}

