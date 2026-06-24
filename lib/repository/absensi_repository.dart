import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/absensi_model.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';

class AbsensiRepository {
  final _client = Supabase.instance.client;

  // Mengambil shift aktif (clock_out is null) milik admin/owner saat ini
  Future<List<AbsensiModel>> getActiveShifts() async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null || adminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('shifts')
          .select('*, employees!inner(*)')
          .eq('employees.admin_id', adminId)
          .isFilter('clock_out', null);

      return (response as List)
          .map((json) => AbsensiModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat shift aktif: $e');
    }
  }

  // Mengambil riwayat shift yang sudah selesai (clock_out is not null)
  Future<List<AbsensiModel>> getShiftHistory() async {
    try {
      final userPrefs = serviceLocator<UserPreference>();
      final role = userPrefs.getLoginRole();

      var query = _client.from('shifts').select('*, employees!inner(*)');

      if (role == 'admin') {
        final adminId = _client.auth.currentUser?.id;
        if (adminId == null || adminId.isEmpty) {
          return [];
        }
        // Jika admin, ambil semua shift milik karyawannya
        query = query.eq(
          'employees.admin_id',
          adminId,
        );
      } else {
        // Jika karyawan, ambil hanya shift miliknya sendiri
        final emp = userPrefs.getEmployee();
        query = query.eq('employee_id', emp?.id ?? '');
      }

      final response = await query
          .not('clock_out', 'is', null)
          .order('clock_in', ascending: false);

      return (response as List)
          .map((json) => AbsensiModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat riwayat shift: $e');
    }
  }

  // Memulai shift baru di database Supabase (Clock In)
  Future<String> startShift({required String employeeId, DateTime? clockIn}) async {
    try {
      final response = await _client
          .from('shifts')
          .insert({
            'employee_id': employeeId,
            'clock_in': (clockIn ?? DateTime.now()).toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Gagal memulai shift: $e');
    }
  }

  // Mengakhiri shift di database Supabase (Clock Out)
  Future<void> endShift({required String shiftId, String? note, DateTime? clockOut}) async {
    try {
      await _client
          .from('shifts')
          .update({
            'clock_out': (clockOut ?? DateTime.now()).toIso8601String(),
            'note': note,
          })
          .eq('id', shiftId);
    } catch (e) {
      throw Exception('Gagal mengakhiri shift: $e');
    }
  }

  // Menghapus catatan shift aktif (Force Logout/Delete)
  Future<void> deleteShift({required String shiftId}) async {
    try {
      await _client.from('shifts').delete().eq('id', shiftId);
    } catch (e) {
      throw Exception('Gagal menghapus shift: $e');
    }
  }
}
