import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static const String _queuePrefix = "offline_queue_";

  // ===========================================================================
  // A. KELOMPOK FITUR: ABSENSI (ATTENDANCE)
  // ===========================================================================

  // 1. Antrean Clock In (Mulai Shift)
  Future<void> saveAttendanceStartQueue(Map<String, dynamic> data) async {
    await _saveToQueue('attendance_start', data);
  }

  Future<List<Map<String, dynamic>>> getAttendanceStartQueue() async {
    return await _getQueue('attendance_start');
  }

  Future<void> removeAttendanceStartQueue(String localId) async {
    await _removeFromQueue('attendance_start', 'id', localId);
  }

  // 2. Antrean Clock Out (Selesai Shift)
  Future<void> saveAttendanceEndQueue(Map<String, dynamic> data) async {
    await _saveToQueue('attendance_end', data);
  }

  Future<List<Map<String, dynamic>>> getAttendanceEndQueue() async {
    return await _getQueue('attendance_end');
  }

  Future<void> removeAttendanceEndQueue(String shiftId) async {
    await _removeFromQueue('attendance_end', 'id', shiftId);
  }

  // ===========================================================================
  // B. KELOMPOK FITUR: TRANSAKSI / PESANAN (ADD ORDER)
  // ===========================================================================

  Future<void> saveOrderQueue(Map<String, dynamic> data) async {
    await _saveToQueue('orders', data);
  }

  Future<List<Map<String, dynamic>>> getOrderQueue() async {
    return await _getQueue('orders');
  }

  Future<void> removeOrderQueue(String localId) async {
    await _removeFromQueue('orders', 'id', localId);
  }

  // ===========================================================================
  // C. KELOMPOK FITUR: KATALOG / STOK BAHAN BAKU (STOCK ADJUSTMENT)
  // ===========================================================================

  Future<void> saveStockQueue(Map<String, dynamic> data) async {
    await _saveToQueue('stock_adjustments', data);
  }

  Future<List<Map<String, dynamic>>> getStockQueue() async {
    return await _getQueue('stock_adjustments');
  }

  Future<void> removeStockQueue(String localId) async {
    await _removeFromQueue('stock_adjustments', 'id', localId);
  }

  // ===========================================================================
  // CORE ENGINE / METODE UTAMA (Private Methods)
  // ===========================================================================

  // Menyimpan JSON ke SharedPreferences
  Future<void> _saveToQueue(String queueType, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_queuePrefix$queueType';

    final existingList = prefs.getStringList(key) ?? [];
    existingList.add(json.encode(data));
    await prefs.setStringList(key, existingList);
  }

  // Mengambil daftar JSON dari SharedPreferences
  Future<List<Map<String, dynamic>>> _getQueue(String queueType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_queuePrefix$queueType';

    final list = prefs.getStringList(key) ?? [];
    return list
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();
  }

  // Menghapus data spesifik dari SharedPreferences berdasarkan key pencocokan
  Future<void> _removeFromQueue(
    String queueType,
    String matchKey,
    dynamic matchValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_queuePrefix$queueType';

    final list = prefs.getStringList(key) ?? [];
    final updatedList = list.where((itemString) {
      final map = json.decode(itemString) as Map<String, dynamic>;
      return map[matchKey] != matchValue;
    }).toList();

    await prefs.setStringList(key, updatedList);
  }

  // Membersihkan seluruh antrean
  Future<void> clearQueue(String queueType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_queuePrefix$queueType';
    await prefs.remove(key);
  }

  // ===========================================================================
  // D. KELOMPOK FITUR: CACHE CATALOG & CATEGORIES (OFFLINE CACHING)
  // ===========================================================================
  static const String _productsCacheKey = "cached_products";
  static const String _categoriesCacheKey = "cached_categories";

  // Simpan cache produk
  Future<void> saveProductsCache(List<Map<String, dynamic>> productsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList = productsJson.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_productsCacheKey, stringList);
  }

  // Ambil cache produk
  Future<List<Map<String, dynamic>>> getProductsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_productsCacheKey) ?? [];
    return list.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  // Simpan cache kategori
  Future<void> saveCategoriesCache(List<Map<String, dynamic>> categoriesJson) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList = categoriesJson.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_categoriesCacheKey, stringList);
  }

  // Ambil cache kategori
  Future<List<Map<String, dynamic>>> getCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_categoriesCacheKey) ?? [];
    return list.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  static const String _ingredientsCacheKey = "cached_ingredients";

  // Simpan cache bahan baku
  Future<void> saveIngredientsCache(List<Map<String, dynamic>> ingredientsJson) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList = ingredientsJson.map((item) => json.encode(item)).toList();
    await prefs.setStringList(_ingredientsCacheKey, stringList);
  }

  // Ambil cache bahan baku
  Future<List<Map<String, dynamic>>> getIngredientsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_ingredientsCacheKey) ?? [];
    return list.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  static const String _dashboardCacheKey = "cached_dashboard_data";

  // Simpan cache data dashboard
  Future<void> saveDashboardCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardCacheKey, json.encode(data));
  }

  // Ambil cache data dashboard
  Future<Map<String, dynamic>?> getDashboardCache() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_dashboardCacheKey);
    if (dataStr == null) return null;
    return json.decode(dataStr) as Map<String, dynamic>;
  }
}
