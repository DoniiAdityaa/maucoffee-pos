import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/employee_model.dart';

class EmployeeRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar karyawan aktif milik admin saat ini
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('admin_id', _client.auth.currentUser?.id ?? '')
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
      // JANGAN hapus 'id' karena kita menggunakan device_uuid sebagai primary key id
      json.remove('created_at');
      // Set admin_id jika belum diset
      json['admin_id'] ??= _client.auth.currentUser?.id;

      await _client.from('employees').insert(json);
    } catch (e) {
      throw Exception('Gagal menambah karyawan: $e');
    }
  }

  // Mengambil data karyawan berdasarkan ID (device_uuid)
  Future<EmployeeModel?> getEmployeeById(String id) async {
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return EmployeeModel.fromJson(response);
    } catch (e) {
      return null;
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

  // Memastikan admin terdaftar sebagai employee record
  Future<void> ensureAdminAsEmployee({
    required String adminId,
    required String name,
    String? email,
  }) async {
    try {
      final existing = await getEmployeeById(adminId);
      if (existing == null) {
        final adminEmp = EmployeeModel(
          id: adminId,
          adminId: adminId,
          name: name,
          role: 'Admin',
          email: email,
          isActive: true,
        );
        await addEmployee(adminEmp);
      }
    } catch (e) {
      // Abaikan error agar tidak menghalangi login
      print("Gagal mendaftarkan Admin sebagai Employee record: $e");
    }
  }
}
