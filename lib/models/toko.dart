class Toko {
  final int? idToko;
  final String namaToko;
  final String? slogan;
  final String? alamat;
  final String? telepon;
  final String? logo; // Path to image or base64
  final String? tiktok;
  final String? instagram;
  final String? facebook;
  final String? web;
  final String? telegramToken;
  final String? telegramChatId;

  Toko({
    this.idToko,
    required this.namaToko,
    this.slogan,
    this.alamat,
    this.telepon,
    this.logo,
    this.tiktok,
    this.instagram,
    this.facebook,
    this.web,
    this.telegramToken,
    this.telegramChatId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_toko': idToko,
      'nama_toko': namaToko,
      'slogan': slogan,
      'alamat': alamat,
      'telepon': telepon,
      'logo': logo,
      'tiktok': tiktok,
      'instagram': instagram,
      'facebook': facebook,
      'web': web,
      'telegram_token': telegramToken,
      'telegram_chat_id': telegramChatId,
    };
  }

  factory Toko.fromMap(Map<String, dynamic> map) {
    return Toko(
      idToko: map['id_toko'],
      namaToko: map['nama_toko'] ?? '',
      slogan: map['slogan'],
      alamat: map['alamat'],
      telepon: map['telepon'],
      logo: map['logo'],
      tiktok: map['tiktok'],
      instagram: map['instagram'],
      facebook: map['facebook'],
      web: map['web'],
      telegramToken: map['telegram_token'],
      telegramChatId: map['telegram_chat_id'],
    );
  }
}
