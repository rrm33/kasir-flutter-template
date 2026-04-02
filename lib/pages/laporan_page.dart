import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String _filterType = "Harian"; // Harian, Mingguan, Bulanan, Kustom
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _bestSelling = [];
  bool _isLoading = true;
  double _totalOmsetKeseluruhan = 0.0;

  @override
  void initState() {
    super.initState();
    _setFilter(_filterType);
  }

  Future<void> _setFilter(String type) async {
    final now = DateTime.now();
    DateTime start = _startDate;
    DateTime end = _endDate;

    if (type == "Harian") {
      start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (type == "Mingguan") {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day, 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (type == "Bulanan") {
      start = DateTime(now.year, now.month, 1, 0, 0, 0);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (type == "Kustom") {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      );
      if (picked != null) {
        start = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      } else {
        return; // Batal pilih
      }
    }

    setState(() {
      _filterType = type;
      _startDate = start;
      _endDate = end;
      _isLoading = true;
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    final db = DatabaseHelper.instance;
    final summary = await db.getReportSummary(_startDate, _endDate);
    final catStats = await db.getCategoryStats(_startDate, _endDate);
    final bestSelling = await db.getBestSellingItems(_startDate, _endDate);

    final totalKeseluruhan = await db.getTotalOmset();

    setState(() {
      _summary = summary;
      _categoryStats = catStats;
      _bestSelling = bestSelling;
      _totalOmsetKeseluruhan = totalKeseluruhan;
      _isLoading = false;
    });
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String _getPeriodLabel() {
    final startStr = DateFormat('dd MMM yyyy').format(_startDate);
    final endStr = DateFormat('dd MMM yyyy').format(_endDate);
    
    if (_filterType == "Harian") {
      return "Hari ini ($startStr)";
    } else if (_filterType == "Mingguan") {
      return "Minggu ini ($startStr - $endStr)";
    } else if (_filterType == "Bulanan") {
      return "Bulan ini ($startStr - $endStr)";
    } else {
      return "Periode: $startStr - $endStr";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Laporan Penjualan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterToggle(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _getPeriodLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Penjualan per Kategori"),
                          const SizedBox(height: 12),
                          _buildCategoryStats(),
                          const SizedBox(height: 24),
                          _buildSectionTitle("Barang Paling Laris"),
                          const SizedBox(height: 12),
                          _buildBestSellingList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterButton("Harian"),
            const SizedBox(width: 8),
            _filterButton("Mingguan"),
            const SizedBox(width: 8),
            _filterButton("Bulanan"),
            const SizedBox(width: 8),
            _filterButton("Kustom"),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String type) {
    bool isSelected = _filterType == type;
    return ElevatedButton(
      onPressed: () => _setFilter(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(type),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            _summaryCard("Omset Filter", _formatCurrency((_summary['total_omset'] as num?)?.toDouble() ?? 0.0), Icons.payments, Colors.green),
            const SizedBox(width: 12),
            _summaryCard("Omset Keseluruhan", _formatCurrency(_totalOmsetKeseluruhan), Icons.account_balance, Colors.purple),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard("Total Profit", _formatCurrency((_summary['total_profit'] as num?)?.toDouble() ?? 0.0), Icons.trending_up, Colors.blue),
            const SizedBox(width: 12),
            _summaryCard("Transaksi", (_summary['total_transaksi'] ?? 0).toString(), Icons.receipt_long, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard("Total Modal", _formatCurrency((_summary['total_modal'] as num?)?.toDouble() ?? 0.0), Icons.account_balance_wallet, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87));
  }

  Widget _buildCategoryStats() {
    if (_categoryStats.isEmpty) {
      return _emptyState("Belum ada data kategori");
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categoryStats.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _categoryStats[index];
          return ListTile(
            title: Text(item['kategori'], style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${item['total_qty']} item terjual"),
            trailing: Text(_formatCurrency((item['total_omset'] as num).toDouble()), 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          );
        },
      ),
    );
  }

  Widget _buildBestSellingList() {
    if (_bestSelling.isEmpty) {
      return _emptyState("Belum ada data barang");
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _bestSelling.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _bestSelling[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Text("${index + 1}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
            title: Text(item['nama_barang'], style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${item['total_qty']} terjual"),
            trailing: Text(_formatCurrency((item['total_omset'] as num).toDouble())),
          );
        },
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
