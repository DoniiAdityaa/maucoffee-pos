import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/repository/cafe_profile_repository.dart';
import 'package:maucoffee/model/cafe_profile_model.dart';
import 'package:maucoffee/services/sync_manager.dart';

part 'setting_state.dart';

class SettingCubit extends Cubit<SettingState> {
  final CafeProfileRepository _profileRepo;
  final UserPreference _userPrefs;

  static const String keyCafeName = "settings_cafe_name";
  static const String keyCafeAddress = "settings_cafe_address";
  static const String keyCafePhone = "settings_cafe_phone";
  static const String keyPaperSize = "settings_paper_size";
  static const String keyLastSync = "settings_last_sync";

  SettingCubit(this._profileRepo, this._userPrefs)
    : super(SettingState.initial());

  // Memuat data lokal SharedPreferences + Fetch Cloud Supabase
  Future<void> loadSettings() async {
    try {
      final prefs = _userPrefs.prefs;
      final cafeName = prefs.getString(keyCafeName) ?? "Maucoffee POS";
      final cafeAddress =
          prefs.getString(keyCafeAddress) ??
          "Jl. Kenangan Manis No. 45, Jakarta";
      final cafePhone = prefs.getString(keyCafePhone) ?? "0812-3456-7890";
      final paperSize = prefs.getString(keyPaperSize) ?? "58mm";
      final lastSyncTime =
          prefs.getString(keyLastSync) ?? "Belum pernah sinkronisasi";

      // Emit data lokal instan agar langsung tampil di UI
      emit(
        state.copyWith(
          cafeName: cafeName,
          cafeAddress: cafeAddress,
          cafePhone: cafePhone,
          paperSize: paperSize,
          lastSyncTime: lastSyncTime,
          isLoading: false,
        ),
      );

      // Asynchronous fetch dari Supabase Cloud dengan timeout 3 detik
      final cloudProfile = await _profileRepo.getProfile().timeout(
        const Duration(seconds: 3),
      );

      if (cloudProfile != null) {
        await prefs.setString(keyCafeName, cloudProfile.name);
        await prefs.setString(keyCafeAddress, cloudProfile.address);
        await prefs.setString(keyCafePhone, cloudProfile.phone);

        emit(
          state.copyWith(
            cafeName: cloudProfile.name,
            cafeAddress: cloudProfile.address,
            cafePhone: cloudProfile.phone,
          ),
        );
      }
    } catch (e) {
      // Jika terjadi timeout atau offline, biarkan data lokal tetap berjalan mulus
      debugPrint("Pemuatan profil dari cloud dilewati (offline/timeout): $e");
    }
  }

  // Menyimpan profil kafe ke lokal (SharedPreferences) & Cloud (Supabase)
  Future<void> saveCafeProfile({
    required String name,
    required String address,
    required String phone,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = _userPrefs.prefs;
      await prefs.setString(keyCafeName, name);
      await prefs.setString(keyCafeAddress, address);
      await prefs.setString(keyCafePhone, phone);

      final profile = CafeProfileModel(
        id: 'default',
        name: name,
        address: address,
        phone: phone,
        updatedAt: DateTime.now(),
      );
      await _profileRepo.saveProfile(profile);

      emit(
        state.copyWith(
          cafeName: name,
          cafeAddress: address,
          cafePhone: phone,
          isLoading: false,
          successMessage: "Profil kafe berhasil diperbarui ke Cloud!",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "Gagal menyimpan profil: $e",
        ),
      );
    }
  }

  // Mengubah ukuran kertas cetak di SharedPreferences
  Future<void> savePaperSize(String size) async {
    try {
      final prefs = _userPrefs.prefs;
      await prefs.setString(keyPaperSize, size);
      emit(
        state.copyWith(
          paperSize: size,
          successMessage: "Ukuran kertas printer diubah menjadi $size",
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: "Gagal menyimpan ukuran kertas: $e"));
    }
  }

  // Melakukan sinkronisasi riil upload offline & update data kafe
  Future<void> syncAllData() async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));

    try {
      // 1. Upload Data Offline
      await SyncManager().syncAllData();

      // 2. Download Profil Kafe Ter-Update
      final cloudProfile = await _profileRepo.getProfile();
      final prefs = _userPrefs.prefs;
      if (cloudProfile != null) {
        await prefs.setString(keyCafeName, cloudProfile.name);
        await prefs.setString(keyCafeAddress, cloudProfile.address);
        await prefs.setString(keyCafePhone, cloudProfile.phone);
      }

      final now = DateTime.now();
      final formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(now);
      final lastSyncString = "Terakhir sinkronisasi: $formattedTime";
      await prefs.setString(keyLastSync, lastSyncString);

      emit(
        state.copyWith(
          cafeName: cloudProfile?.name ?? state.cafeName,
          cafeAddress: cloudProfile?.address ?? state.cafeAddress,
          cafePhone: cloudProfile?.phone ?? state.cafePhone,
          lastSyncTime: lastSyncString,
          isSyncing: false,
          successMessage:
              "Sinkronisasi Berhasil! Seluruh transaksi offline diunggah dan database lokal diperbarui.",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSyncing: false,
          errorMessage: "Sinkronisasi Gagal: $e",
        ),
      );
    }
  }
}
