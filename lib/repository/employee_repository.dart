import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/employee_model.dart';

class EmployeeRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar karyawan aktif
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _client
          .from('employees')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => EmployeeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat karyawan: $e');
    }
  }

  // Menambah karyawan baru
  Future<void> addEmployee(EmployeeModel employee) async {
    try {
      final json = employee.toJson();
      json.remove('id');
      json.remove('created_at');

      await _client.from('employees').insert(json);
    } catch (e) {
      throw Exception('Gagal menambah karyawan: $e');
    }
  }

  // Mengubah status atau peran karyawan
  Future<void> updateEmployee(EmployeeModel employee) async {
    if (employee.id == null) return;
    try {
      final json = employee.toJson();
      json.remove('created_at');

      await _client.from('employees').update(json).eq('id', employee.id!);
    } catch (e) {
      throw Exception('Gagal mengubah data karyawan: $e');
    }
  }
}
