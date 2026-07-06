import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/expense_model.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';

class ExpenseRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar pengeluaran toko
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final targetAdminId = serviceLocator<UserPreference>().getActiveAdminId();
      if (targetAdminId == null || targetAdminId.isEmpty) {
        return [];
      }

      final response = await _client
          .from('expenses')
          .select()
          .eq('admin_id', targetAdminId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat data pengeluaran: $e');
    }
  }

  // Menambah catatan pengeluaran baru
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final json = expense.toJson();
      json.remove('id');
      
      // Set admin_id jika belum diset
      json['admin_id'] ??= serviceLocator<UserPreference>().getActiveAdminId();

      // Gunakan created_at dari model agar custom date dari user tersimpan
      if (expense.createdAt != null) {
        json['created_at'] = expense.createdAt!.toIso8601String();
      } else {
        json.remove('created_at');
      }

      await _client.from('expenses').insert(json);
    } catch (e) {
      throw Exception('Gagal mencatat pengeluaran: $e');
    }
  }

  // Menghapus catatan pengeluaran berdasarkan ID
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _client.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      throw Exception('Gagal menghapus pengeluaran: $e');
    }
  }
}
