import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/transaksi.dart';

class TelegramService {
  // Masukkan Token dan Chat ID Anda di sini
  static const String _token =
      "8592025771:AAEbgMilDjsMMoPEE2fefsKDbOMk_c8mu8A"; // Ganti dengan token Anda
  static const String _chatId = "390683293"; // Ganti dengan chat ID Anda

  static Future<void> sendNotification({
    required String namaKasir,
    required Transaksi transaksi,
    required double saldoSetelah,
  }) async {
    if (_token.isEmpty || _chatId.isEmpty) {
      return;
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final String message =
        "<b>🚀 TRANSAKSI BARU</b>\n"
        "--------------------------------\n"
        "<b>No. Trx:</b> ${transaksi.nomorTransaksi ?? "#${transaksi.idTransaksi}"}\n"
        "<b>Total:</b> ${currencyFormat.format(transaksi.totalHarga)}\n"
        "<b>Kasir:</b> [${transaksi.idKasir}] $namaKasir\n"
        "<b>Tanggal:</b> ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(transaksi.tglTransaksi))}\n"
        "--------------------------------\n"
        "<b>Bayar:</b> ${currencyFormat.format(transaksi.bayar)}\n"
        "<b>Kembali:</b> ${currencyFormat.format(transaksi.kembalian)}\n"
        "<b>Saldo Akhir:</b> ${currencyFormat.format(saldoSetelah)}\n"
        "--------------------------------\n"
        "<i>Terima kasih!</i>";

    final url = Uri.parse("https://api.telegram.org/bot$_token/sendMessage");

    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "chat_id": _chatId,
          "text": message,
          "parse_mode": "HTML",
        }),
      );
    } catch (e) {
      print("Error sending Telegram notification: $e");
    }
  }

  static Future<void> sendVoidNotification({
    required String namaKasir,
    required Transaksi transaksi,
    required double saldoSetelah,
  }) async {
    if (_token.isEmpty || _chatId.isEmpty) {
      return;
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final String message = "<b>⚠️ TRANSAKSI DIBATALKAN (VOID)</b>\n"
        "--------------------------------\n"
        "<b>No. Trx:</b> ${transaksi.nomorTransaksi ?? "#${transaksi.idTransaksi}"}\n"
        "<b>Total:</b> ${currencyFormat.format(transaksi.totalHarga)}\n"
        "<b>Kasir:</b> [${transaksi.idKasir}] $namaKasir\n"
        "<b>Waktu Batal:</b> ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}\n"
        "--------------------------------\n"
        "<b>Saldo Akhir:</b> ${currencyFormat.format(saldoSetelah)}\n"
        "--------------------------------\n"
        "<i>Peringatan: Stok barang telah dikembalikan.</i>";

    final url = Uri.parse("https://api.telegram.org/bot$_token/sendMessage");

    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "chat_id": _chatId,
          "text": message,
          "parse_mode": "HTML",
        }),
      );
    } catch (e) {
      print("Error sending Telegram Void notification: $e");
    }
  }
}
