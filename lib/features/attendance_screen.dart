import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/config/notification_manager.dart';

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

  final dateFormatter = DateFormat('dd MMM yyyy');
  final timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _loadActiveShift();
    _initNotifications();
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
    final now = DateTime.now();

    setState(() {
      _startTime = now;
      _isShiftActive = true;
      _formattedDuration = "00:00:00";
    });

    // Simpan ke SharedPreferences secara persisten
    await HistoryManager().saveActiveShift(_currentUser, _currentRole, now);
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
      CustomFeedback.showSuccess(context, "Shift kerja berhasil dimulai!");
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
    final endTime = DateTime.now();
    _timer?.cancel();

    // Buat objek riwayat baru
    final newAttendance = AttendanceHistory(
      id: "ATT-${100 + (DateTime.now().millisecond) % 900}",
      employeeName: _currentUser,
      role: _currentRole,
      startTime: _startTime!,
      endTime: endTime,
      note: note.isNotEmpty ? note : null,
    );

    // Simpan ke HistoryManager
    HistoryManager().addAttendance(newAttendance);

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
      Navigator.pop(context); // Tutup dialog
      CustomFeedback.showSuccess(
        context,
        "Shift kerja berhasil diakhiri & tercatat!",
      );
    }
  }

  // Menampilkan Dialog Konfirmasi Hapus Riwayat Absensi
  Future<bool?> _showDeleteConfirmation(AttendanceHistory log) {
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
                      text: log.employeeName,
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
    final logs = HistoryManager().attendanceLogs;

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
              child: logs.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(logs),
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

  Widget _buildHistoryList(List<AttendanceHistory> logs) {
    final admin = _isAdmin;
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: spacing6,
        right: spacing6,
        bottom: 100, // padding agar tidak tertutup floating bar
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];

        return Dismissible(
          key: Key(log.id),
          direction: admin
              ? DismissDirection.endToStart
              : DismissDirection.none,
          secondaryBackground: _buildDismissibleBackground(),
          background: const SizedBox(),
          confirmDismiss: (direction) async {
            final confirm = await _showDeleteConfirmation(log);
            return confirm ?? false;
          },
          onDismissed: (direction) {
            HistoryManager().deleteAttendance(log.id);
            setState(() {});
            CustomFeedback.showSuccess(
              context,
              "Riwayat absensi ${log.employeeName} berhasil dihapus!",
            );
          },
          child: _buildHistoryItem(log),
        );
      },
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

  Widget _buildHistoryItem(AttendanceHistory log) {
    final duration = log.endTime.difference(log.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: spacing3),
      padding: const EdgeInsets.all(spacing4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                    log.employeeName,
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
                      log.role,
                      style: xxxsMedium.copyWith(color: Colors.white60),
                    ),
                  ),
                ],
              ),
              Text(
                dateFormatter.format(log.startTime),
                style: xxsRegular.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Jam Kerja: ${timeFormatter.format(log.startTime)} - ${timeFormatter.format(log.endTime)}",
                style: xxsMedium.copyWith(color: Colors.white54),
              ),
              Text(
                "Durasi: ${_formatDuration(duration)}",
                style: xxsBold.copyWith(color: primaryColor),
              ),
            ],
          ),
          if (log.note != null) ...[
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
    return Center(
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
    );
  }
}
