import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/expense_model.dart';

class ExpenseRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar pengeluaran toko
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await _client
          .from('expenses')
          .select()
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
      json.remove('created_at');

      await _client.from('expenses').insert(json);
    } catch (e) {
      throw Exception('Gagal mencatat pengeluaran: $e');
    }
  }
}
