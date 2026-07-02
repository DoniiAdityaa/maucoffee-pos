import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maucoffee/model/absensi_model.dart';
import 'package:maucoffee/repository/absensi_repository.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/services/offline_storage_service.dart';
import 'package:maucoffee/services/sync_manager.dart';

part 'absensi_state.dart';

class AbsensiCubit extends Cubit<AbsensiState> {
  final AbsensiRepository _absensiRepository;
  StreamSubscription? _syncSubscription;

  AbsensiCubit(this._absensiRepository) : super(const AbsensiState()) {
    _syncSubscription = SyncManager().onSyncCompleted.listen((_) {
      fetchActiveShifts();
      fetchShiftHistory();
    });
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  // Memuat data shift aktif dari database (untuk Admin Dashboard)
  Future<void> fetchActiveShifts() async {
    emit(state.copyWith(status: AbsensiStatus.loading));
    try {
      final activeShifts = await _absensiRepository.getActiveShifts();
      emit(
        state.copyWith(
          status: AbsensiStatus.success,
          activeShifts: activeShifts,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AbsensiStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  // Memuat riwayat shift yang selesai (untuk Riwayat Absensi Karyawan/Admin)
  Future<void> fetchShiftHistory() async {
    emit(state.copyWith(status: AbsensiStatus.loading));
    try {
      final historyShifts = await _absensiRepository.getShiftHistory();

      // Membaca antrean offline
      final offlineStorage = serviceLocator<OfflineStorageService>();
      final startQueue = await offlineStorage.getAttendanceStartQueue();
      final endQueue = await offlineStorage.getAttendanceEndQueue();

      final List<AbsensiModel> offlineModels = [];
      final userPrefs = serviceLocator<UserPreference>();

      // Ubah antrean clock-in offline menjadi AbsensiModel
      for (var startData in startQueue) {
        final localId = startData['id'] as String;
        final employeeId = startData['employee_id'] as String;
        final clockInTime = DateTime.parse(startData['clock_in'] as String);

        // Cari data clock-out offline yang terkait (jika ada)
        final endMatch = endQueue.firstWhere(
          (e) => e['id'] == localId,
          orElse: () => <String, dynamic>{},
        );

        DateTime? clockOutTime;
        String? note;
        if (endMatch.isNotEmpty) {
          clockOutTime = DateTime.parse(endMatch['clock_out'] as String);
          note = endMatch['note'] as String?;
        }

        // Ambil info nama & role dari preferensi pengguna saat ini
        String name = "Owner Maucoffee";
        String roleName = "Admin";

        if (userPrefs.getLoginRole() == 'admin') {
          name = userPrefs.getUser().name ?? "Owner Maucoffee";
          roleName = "Owner";
        } else {
          final emp = userPrefs.getEmployee();
          name = emp?.name ?? "Staf";
          roleName = emp?.role ?? "Staf";
        }

        offlineModels.add(
          AbsensiModel(
            id: localId,
            employeeId: employeeId,
            clockIn: clockInTime,
            clockOut: clockOutTime,
            note: note,
            isSynced: false,
            employees: {
              'name': name,
              'role': roleName,
            },
          ),
        );
      }

      // 2. Cari sisa clock-out offline yang start-nya online (bukan ID 'offline-')
      for (var endData in endQueue) {
        final shiftId = endData['id'] as String;
        if (shiftId.startsWith('offline-')) continue; // Lewati karena sudah di-handle di atas

        final note = endData['note'] as String?;
        final clockOutTime = DateTime.parse(endData['clock_out'] as String);

        // Cari data clock-in di historyShifts online untuk dicocokkan
        final onlineIndex = historyShifts.indexWhere((s) => s.id == shiftId);
        if (onlineIndex != -1) {
          final onlineShift = historyShifts[onlineIndex];
          
          // Ganti dengan data offline clockOut terbaru, pasang isSynced = false
          offlineModels.add(
            AbsensiModel(
              id: onlineShift.id,
              employeeId: onlineShift.employeeId,
              clockIn: onlineShift.clockIn,
              clockOut: clockOutTime,
              note: note ?? onlineShift.note,
              isSynced: false,
              employees: onlineShift.employees,
            ),
          );
          
          // Hapus dari list online agar tidak duplikat
          historyShifts.removeAt(onlineIndex);
        }
      }

      // Gabungkan data offline (belum sinkron) di bagian atas list
      final allShifts = [...offlineModels, ...historyShifts];

      emit(
        state.copyWith(
          status: AbsensiStatus.success,
          historyShifts: allShifts,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AbsensiStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }

  // Memulai Shift Kerja Baru (Clock In)
  Future<String?> startShift({required String employeeId}) async {
    emit(state.copyWith(status: AbsensiStatus.loading));
    try {
      final shiftId = await _absensiRepository.startShift(
        employeeId: employeeId,
      );
      // Refresh data
      await fetchShiftHistory();
      await fetchActiveShifts();
      return shiftId;
    } catch (e) {
      emit(
        state.copyWith(
          status: AbsensiStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
      return null;
    }
  }

  // Mengakhiri Shift Kerja (Clock Out)
  Future<bool> endShift({required String shiftId, String? note}) async {
    emit(state.copyWith(status: AbsensiStatus.loading));
    try {
      await _absensiRepository.endShift(shiftId: shiftId, note: note);
      // Refresh data
      await fetchShiftHistory();
      await fetchActiveShifts();
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AbsensiStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
      return false;
    }
  }

  // Menghapus/Force Logout shift aktif atau riwayat
  Future<void> deleteShift({required String shiftId}) async {
    // Optimistic update: hapus dari list lokal secara sinkron agar Dismissible tidak error
    final updatedHistory = state.historyShifts
        .where((s) => s.id != shiftId)
        .toList();
    final updatedActive = state.activeShifts
        .where((s) => s.id != shiftId)
        .toList();

    emit(
      state.copyWith(
        status: AbsensiStatus.loading,
        historyShifts: updatedHistory,
        activeShifts: updatedActive,
      ),
    );

    try {
      await _absensiRepository.deleteShift(shiftId: shiftId);
      // Refresh data
      await fetchActiveShifts();
      await fetchShiftHistory();
    } catch (e) {
      emit(
        state.copyWith(
          status: AbsensiStatus.error,
          errorMessage: () => e.toString(),
        ),
      );
      // Kembalikan data aslinya dengan me-refresh ulang dari Supabase jika gagal
      await fetchActiveShifts();
      await fetchShiftHistory();
    }
  }
}
