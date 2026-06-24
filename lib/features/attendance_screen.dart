import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/features/cubit/absensi_cubit.dart';
import 'package:maucoffee/model/absensi_model.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:maucoffee/config/notification_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maucoffee/services/offline_storage_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Sesi Pengguna Aktif
  String _currentUser = "Staf Kafe";
  String _currentRole = "Staf";

  // State Shift
  bool _isShiftActive = false;
  DateTime? _startTime;
  String _formattedDuration = "00:00:00";
  Timer? _timer;

  // Local stopwatch state only

  final dateFormatter = DateFormat('dd MMM yyyy');
  final timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _ensureAdminRegistered();
    _loadActiveShift();
    _initNotifications();
    _loadHistoryFromSupabase();
  }

  Future<void> _ensureAdminRegistered() async {
    if (_isAdmin) {
      final userPrefs = serviceLocator<UserPreference>();
      final user = userPrefs.getUser();
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId != null) {
        try {
          final employeeRepo = serviceLocator<EmployeeRepository>();
          await employeeRepo.ensureAdminAsEmployee(
            adminId: adminId,
            name: user.name ?? "Owner Maucoffee",
            email: user.email,
          );
        } catch (e) {
          debugPrint("Gagal mendaftarkan Admin sebagai Employee record: $e");
        }
      }
    }
  }

  Future<void> _loadHistoryFromSupabase() async {
    try {
      await context.read<AbsensiCubit>().fetchShiftHistory();
    } catch (e) {
      debugPrint("Gagal memuat riwayat: $e");
    }
  }

  Future<void> _handleRefresh() async {
    _loadUserSession();
    await _loadActiveShift();
    await _loadHistoryFromSupabase();
  }

  Future<void> _initNotifications() async {
    await NotificationManager.getInstance().init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Getter to check if user is Admin/Owner
  bool get _isAdmin {
    final userPrefs = serviceLocator<UserPreference>();
    return userPrefs.getLoginRole() == 'admin';
  }

  // Mengambil sesi user yang saat ini sedang login secara otomatis
  void _loadUserSession() {
    final userPrefs = serviceLocator<UserPreference>();
    final role = userPrefs.getLoginRole(); // 'admin' atau 'employee'

    if (role == 'admin') {
      final user = userPrefs.getUser();
      setState(() {
        _currentUser = user.name ?? user.username ?? "Owner Maucoffee";
        _currentRole = "Owner";
      });
    } else {
      final emp = userPrefs.getEmployee();
      setState(() {
        _currentUser = emp?.name ?? "Staf Maucoffee";
        _currentRole = emp?.role ?? "Staf";
      });
    }
  }

  // Memulihkan state timer dari SharedPreferences (apabila aplikasi diclose/HP mati)
  Future<void> _loadActiveShift() async {
    final activeShift = await HistoryManager().getActiveShift();
    if (activeShift != null) {
      setState(() {
        _currentUser = activeShift["name"];
        _currentRole = activeShift["role"];
        _startTime = activeShift["startTime"];
        _isShiftActive = true;
      });
      _startTimer();

      // Pastikan pengingat tetap dijadwalkan ulang jika shift aktif
      final now = DateTime.now();
      final scheduleTime = DateTime(
        now.year,
        now.month,
        now.day,
        22,
        0,
      ); // Jam 22:00
      if (now.isBefore(scheduleTime)) {
        await NotificationManager.getInstance().showScheduleNotification(
          id: 999,
          channelId: "maucoffee_attendance",
          channelName: "Reminder Absensi",
          channelDescription:
              "Mengingatkan untuk mematikan stopwatch absensi kerja",
          title: "Stopwatch Maucoffee Masih Aktif!",
          body: "Jangan lupa untuk mematikan stopwatch Maucoffee Anda.",
          payload: "attendance",
          dateTime: scheduleTime,
        );
      }
    }
  }

  // Menjalankan stopwatch real-time
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        final duration = DateTime.now().difference(_startTime!);
        setState(() {
          _formattedDuration = _formatDuration(duration);
        });
      }
    });
  }

  // Memformat objek Duration menjadi format string HH:mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Memulai Shift Kerja
  Future<void> _startShift() async {
    HapticFeedback.mediumImpact();

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );

    final now = DateTime.now();
    String? shiftId;
    final userPrefs = serviceLocator<UserPreference>();
    final role = userPrefs.getLoginRole();

    String? currentEmployeeId;
    if (role == 'employee') {
      currentEmployeeId = userPrefs.getEmployee()?.id;
    } else if (role == 'admin') {
      currentEmployeeId = Supabase.instance.client.auth.currentUser?.id;
    }

    // Cek koneksi internet
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      // PROSES ONLINE
      if (role == 'admin' && currentEmployeeId != null) {
        try {
          final employeeRepo = serviceLocator<EmployeeRepository>();
          final user = userPrefs.getUser();
          await employeeRepo.ensureAdminAsEmployee(
            adminId: currentEmployeeId,
            name: user.name ?? "Owner Maucoffee",
            email: user.email,
          );
        } catch (e) {
          debugPrint("Gagal mendaftarkan admin sebelum mulai shift: $e");
        }
      }

      if (currentEmployeeId != null) {
        try {
          shiftId = await context.read<AbsensiCubit>().startShift(
            employeeId: currentEmployeeId,
          );
        } catch (e) {
          debugPrint("Gagal mencatat shift di Supabase: $e");
        }
      }
    } else {
      // PROSES OFFLINE
      debugPrint(" Mulai shift kerja secara offline...");
      if (currentEmployeeId != null) {
        shiftId = "offline-${DateTime.now().millisecondsSinceEpoch}";
        final offlineData = {
          'id': shiftId,
          'employee_id': currentEmployeeId,
          'clock_in': now.toIso8601String(),
        };
        try {
          await serviceLocator<OfflineStorageService>()
              .saveAttendanceStartQueue(offlineData);
        } catch (e) {
          debugPrint("Gagal menyimpan antrean start offline: $e");
          shiftId = null;
        }
      }
    }

    if (mounted) {
      Navigator.pop(context); // Tutup loading dialog
    }

    if (shiftId == null) {
      if (mounted) {
        final errorMsg = context.read<AbsensiCubit>().state.errorMessage;
        CustomFeedback.showError(
          context,
          errorMsg != null && errorMsg.isNotEmpty
              ? "Gagal memulai shift: $errorMsg"
              : "Gagal memulai shift kerja. Pastikan penyimpanan internal Anda mencukupi.",
        );
      }
      return;
    }

    setState(() {
      _startTime = now;
      _isShiftActive = true;
      _formattedDuration = "00:00:00";
    });

    // Simpan ke SharedPreferences secara persisten
    await HistoryManager().saveActiveShift(
      _currentUser,
      _currentRole,
      now,
      shiftId,
    );
    _startTimer();

    // Jadwalkan notifikasi pengingat untuk pukul 22:00 malam itu
    final scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      22,
      0,
    ); // Jam 22:00
    if (now.isBefore(scheduleTime)) {
      await NotificationManager.getInstance().showScheduleNotification(
        id: 999,
        channelId: "maucoffee_attendance",
        channelName: "Reminder Absensi",
        channelDescription:
            "Mengingatkan untuk mematikan stopwatch absensi kerja",
        title: "Stopwatch Maucoffee Masih Aktif!",
        body: "Jangan lupa untuk mematikan stopwatch Maucoffee Anda.",
        payload: "attendance",
        dateTime: scheduleTime,
      );
    }

    if (mounted) {
      if (isOnline) {
        CustomFeedback.showSuccess(context, "Shift kerja berhasil dimulai!");
      } else {
        CustomFeedback.showWarning(
          context,
          "Shift kerja dimulai secara offline! Data disimpan di HP & akan disinkronkan saat ada internet.",
        );
      }
    }
  }

  // Menampilkan Dialog Akhiri Shift (Clock Out) & Handover Note
  void _showStopShiftDialog() {
    HapticFeedback.mediumImpact();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A1A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(spacing5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Akhiri Shift Kerja",
                style: mdBold.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                "Durasi kerja Anda hari ini: $_formattedDuration",
                style: xxsMedium.copyWith(color: primaryColor),
              ),
              const Divider(color: Colors.white10, height: 20),

              // Handover Note Input
              Text(
                "Catatan Serah Terima (Opsional)",
                style: xsBold.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: spacing3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: sMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        "Contoh: Sisa cup 30 pcs, mesin espresso sudah dibersihkan.",
                    hintStyle: sMedium.copyWith(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: spacing5),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: spacing3),
                      ),
                      child: Text(
                        "Batal",
                        style: sBold.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _stopShift(noteController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: spacing3),
                      ),
                      child: Text(
                        "Simpan & Akhiri",
                        style: sBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menyelesaikan Shift Kerja
  Future<void> _stopShift(String note) async {
    _timer?.cancel();

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );

    // Panggil Supabase untuk clock-out jika ada shiftId tersimpan
    final activeShift = await HistoryManager().getActiveShift();
    final shiftId = activeShift?["shiftId"];
    final now = DateTime.now();
    bool success = false;
    bool wasOffline = false;

    // Cek koneksi internet
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (shiftId != null) {
      if (isOnline && !shiftId.startsWith('offline-')) {
        // PROSES ONLINE
        try {
          success = await context.read<AbsensiCubit>().endShift(
            shiftId: shiftId,
            note: note.isNotEmpty ? note : null,
          );
        } catch (e) {
          debugPrint("Gagal mengakhiri shift di Supabase: $e");
        }
      } else {
        // PROSES OFFLINE (atau ID mulai-nya kemarin offline)
        debugPrint("Mengakhiri shift kerja secara offline...");
        wasOffline = true;
        final offlineData = {
          'id': shiftId,
          'note': note,
          'clock_out': now.toIso8601String(),
        };
        try {
          await serviceLocator<OfflineStorageService>().saveAttendanceEndQueue(
            offlineData,
          );
          success = true;
        } catch (e) {
          debugPrint("Gagal menyimpan antrean end offline: $e");
        }
      }
    } else {
      debugPrint("Gagal mengakhiri shift: shiftId is null");
    }

    if (mounted) {
      Navigator.pop(context); // Tutup loading dialog
    }

    if (!success) {
      if (mounted) {
        final errorMsg = context.read<AbsensiCubit>().state.errorMessage;
        CustomFeedback.showError(
          context,
          errorMsg != null && errorMsg.isNotEmpty
              ? "Gagal mengakhiri shift: $errorMsg"
              : "Gagal mencatat jam selesai. Silakan coba lagi.",
        );
      }
      _startTimer(); // Restart local timer so stopwatch keeps running
      return;
    }

    // Bersihkan data dari SharedPreferences
    await HistoryManager().clearActiveShift();

    // Batalkan pengingat absensi jam 10 malam terjadwal karena shift sudah berakhir
    await NotificationManager.getInstance().cancelNotification(999);

    setState(() {
      _isShiftActive = false;
      _startTime = null;
      _formattedDuration = "00:00:00";
    });

    if (mounted) {
      Navigator.pop(context); // Tutup dialog input note
      if (!wasOffline) {
        CustomFeedback.showSuccess(
          context,
          "Shift kerja berhasil diakhiri & tercatat!",
        );
      } else {
        CustomFeedback.showWarning(
          context,
          "Shift kerja diakhiri secara offline! Data disimpan di HP & akan disinkronkan saat ada internet.",
        );
      }
    }
  }

  // Menampilkan Dialog Konfirmasi Hapus Riwayat Absensi
  Future<bool?> _showDeleteConfirmation(AbsensiModel log) {
    HapticFeedback.heavyImpact();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E140A).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(spacing5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: errorColor,
                size: 48,
              ),
              const SizedBox(height: spacing4),
              Text(
                "Hapus Riwayat Absensi",
                style: mdBold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: spacing3),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: sRegular.copyWith(color: Colors.white70),
                  children: [
                    const TextSpan(
                      text:
                          "Apakah Anda yakin ingin menghapus catatan absensi milik ",
                    ),
                    TextSpan(
                      text: log.employeeName ?? "Staf",
                      style: sBold.copyWith(color: primaryColor),
                    ),
                    const TextSpan(
                      text: "? Tindakan ini tidak dapat dibatalkan.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: spacing6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: spacing3),
                      ),
                      child: Text(
                        "Batal",
                        style: sBold.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: spacing3),
                      ),
                      child: Text(
                        "Hapus",
                        style: sBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CORE BUILD METHOD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildUserSessionCard(),
            const SizedBox(height: spacing4),
            _buildShiftStatusCard(),
            const SizedBox(height: spacing5),
            _buildHistorySectionHeader(),
            const SizedBox(height: spacing3),
            Expanded(
              child: BlocBuilder<AbsensiCubit, AbsensiState>(
                builder: (context, state) {
                  if (state.status == AbsensiStatus.loading &&
                      state.historyShifts.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    );
                  }

                  final historyLogs = state.historyShifts;
                  if (historyLogs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildHistoryList(historyLogs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUB WIDGET BUILDERS ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing6,
        vertical: spacing3,
      ),
      child: Text("Absensi", style: lgBold.copyWith(color: Colors.white)),
    );
  }

  Widget _buildUserSessionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacing6),
      child: Container(
        padding: const EdgeInsets.all(spacing4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(spacing3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: spacing4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser,
                    style: sBold.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Login sebagai: $_currentRole",
                    style: xxsMedium.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacing6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: spacing6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isShiftActive
                ? primaryColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              _formattedDuration,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                fontFamily: 'poppins',
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: spacing1),
            Text(
              _isShiftActive
                  ? "Shift Kerja Sedang Berjalan (Mulai: ${timeFormatter.format(_startTime!)})"
                  : "Belum Ada Shift Berjalan",
              style: xxsMedium.copyWith(
                color: _isShiftActive ? primaryColor : Colors.white30,
              ),
            ),
            const SizedBox(height: spacing5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing5),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isShiftActive
                      ? _showStopShiftDialog
                      : _startShift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isShiftActive
                        ? Colors.redAccent
                        : primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _isShiftActive ? 2 : 4,
                    shadowColor: _isShiftActive
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : primaryColor.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isShiftActive
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isShiftActive ? "Akhiri Kerja" : "Mulai Kerja",
                        style: sBold.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacing6),
      child: Text(
        "Riwayat Absensi Terbaru",
        style: sBold.copyWith(color: Colors.white70),
      ),
    );
  }

  Widget _buildHistoryList(List<AbsensiModel> logs) {
    final admin = _isAdmin;
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFE27D00),
      backgroundColor: const Color(0xFF2A1A0A),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: spacing6,
          right: spacing6,
          bottom: 100, // padding agar tidak tertutup floating bar
        ),
        itemCount: logs.length,
        itemBuilder: (_, index) {
          final log = logs[index];

          return Dismissible(
            key: Key(log.id ?? 'shift-$index'),
            direction: admin
                ? DismissDirection.endToStart
                : DismissDirection.none,
            secondaryBackground: _buildDismissibleBackground(),
            background: const SizedBox(),
            confirmDismiss: (direction) async {
              final confirm = await _showDeleteConfirmation(log);
              return confirm ?? false;
            },
            onDismissed: (direction) async {
              if (log.id != null) {
                try {
                  await context.read<AbsensiCubit>().deleteShift(
                    shiftId: log.id!,
                  );
                  if (!mounted) return;
                  CustomFeedback.showSuccess(
                    context,
                    "Riwayat absensi ${log.employeeName ?? 'Staf'} berhasil dihapus!",
                  );
                } catch (e) {
                  if (!mounted) return;
                  CustomFeedback.showError(
                    context,
                    "Gagal menghapus riwayat: $e",
                  );
                }
              }
            },
            child: _buildHistoryItem(log),
          );
        },
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: spacing3),
      padding: const EdgeInsets.symmetric(horizontal: spacing5),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, errorColor.withValues(alpha: 0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Hapus", style: sBold.copyWith(color: errorColor)),
          const SizedBox(width: spacing3),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AbsensiModel log) {
    final endTime = log.clockOut ?? log.clockIn;
    final duration = endTime.difference(log.clockIn);

    return Container(
      margin: const EdgeInsets.only(bottom: spacing3),
      padding: const EdgeInsets.all(spacing4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.isSynced
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFFF9E22).withValues(alpha: 0.3),
          width: log.isSynced ? 1.0 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    log.employeeName ?? "Staf",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.employeeRole ?? "Staf",
                      style: xxxsMedium.copyWith(color: Colors.white60),
                    ),
                  ),
                  if (!log.isSynced) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9E22).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFF9E22).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Color(0xFFFF9E22),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Belum Sinkron",
                            style: xxsBold.copyWith(
                              color: const Color(0xFFFF9E22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                dateFormatter.format(log.clockIn),
                style: xxsRegular.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Jam Kerja: ${timeFormatter.format(log.clockIn.toLocal())} - ${timeFormatter.format(endTime.toLocal())}",
                style: xxsMedium.copyWith(color: Colors.white54),
              ),
              Text(
                "Durasi: ${_formatDuration(duration)}",
                style: xxsBold.copyWith(color: primaryColor),
              ),
            ],
          ),
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log.note!,
                    style: xxsRegular.copyWith(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFE27D00),
      backgroundColor: const Color(0xFF2A1A0A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white12,
                      size: 48,
                    ),
                    const SizedBox(height: spacing2),
                    Text(
                      "Belum ada riwayat absensi kerja.",
                      style: sMedium.copyWith(color: Colors.white30),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
