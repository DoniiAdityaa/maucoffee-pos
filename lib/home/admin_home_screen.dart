import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/auth/admin_scan_employee_screen.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Welcome Messages
  String _welcomeMessage = "Halo, Owner! 👋";
  String _welcomeSubtitle = "Kelola tokomu dan tim dari sini";
  bool _isAdmin = true;

  // locked staff
  final bool isLocked = true;

  // Store status state
  bool _isStoreOpen = false;
  DateTime? _storeOpenTime;
  Duration _storeDuration = Duration.zero;
  Timer? _storeTimer;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Active Staff Shift Tracker Mock (using Cashier role)
  final List<Map<String, dynamic>> _activeStaffShift = [
    {
      'id': '1',
      'name': 'Ahmad Dani',
      'role': 'Cashier',
      'clockIn': '08:00 AM',
      'avatarColor': const Color(0xFFE27D00),
    },
    {
      'id': '2',
      'name': 'Siti Rahma',
      'role': 'Cashier',
      'clockIn': '09:15 AM',
      'avatarColor': const Color(0xFF2D8A4E),
    },
  ];

  // Best Selling Items Mock
  final List<Map<String, dynamic>> _bestSellers = [
    {
      'name': 'Es Kopi Susu',
      'sales': '32 Cups',
      'revenue': 576000.0,
      'trend': '+15%',
    },
    {
      'name': 'Caramel Macchiato',
      'sales': '18 Cups',
      'revenue': 396000.0,
      'trend': '+8%',
    },
    {
      'name': 'Almond Croissant',
      'sales': '12 Pcs',
      'revenue': 300000.0,
      'trend': '+5%',
    },
  ];

  // Low Stock Items Mock
  final List<Map<String, dynamic>> _lowStockItems = [
    {'name': 'Fresh Milk UHT', 'stock': '3 Pcs left'},
    {'name': 'Arabica Coffee Beans', 'stock': '1.5 kg left'},
  ];

  // Recent Transactions Preview Mock
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'id': 'TRX-9482',
      'items': 'Es Kopi Susu x2, Almond Croissant',
      'time': '10:14 AM',
      'amount': 54000.0,
    },
    {
      'id': 'TRX-9481',
      'items': 'Caramel Macchiato, Espresso',
      'time': '09:55 AM',
      'amount': 48000.0,
    },
    {
      'id': 'TRX-9480',
      'items': 'Americano Coffee',
      'time': '09:30 AM',
      'amount': 22000.0,
    },
  ];

  // Weekly sales chart data points (Mocked Indonesian Rupiah values in thousands)
  final List<double> _weeklySalesData = [450, 620, 580, 890, 720, 1100, 950];
  final List<String> _weeklySalesDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _loadUserSession();
  }

  void _loadUserSession() {
    final userPrefs = serviceLocator<UserPreference>();
    final role = userPrefs.getLoginRole(); // 'admin' atau 'employee'

    setState(() {
      _isAdmin = (role == 'admin');
    });

    if (role == 'admin') {
      final user = userPrefs.getUser();
      final name = user.name ?? user.username ?? "Owner";
      setState(() {
        _welcomeMessage = "Halo, $name! 👋";
        _welcomeSubtitle = "Kelola tokomu dan tim dari sini";
      });
    } else {
      final emp = userPrefs.getEmployee();
      final name = emp?.name ?? "Staf";
      setState(() {
        _welcomeMessage = "Halo, $name! 👋";
        _welcomeSubtitle = "Pantau shift kerja dan aktivitasmu di sini";
      });
    }
  }

  @override
  void dispose() {
    _storeTimer?.cancel();
    super.dispose();
  }

  // Toggle Store Status & Timer
  void _toggleStoreStatus() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isStoreOpen = !_isStoreOpen;
      if (_isStoreOpen) {
        _storeOpenTime = DateTime.now();
        _storeDuration = Duration.zero;
        _storeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _storeDuration = DateTime.now().difference(_storeOpenTime!);
            });
          }
        });
      } else {
        _storeTimer?.cancel();
        _storeTimer = null;
        _storeOpenTime = null;
        _storeDuration = Duration.zero;
      }
    });
  }

  // Delete Staff Shift History (Admin specific control)
  void _deleteStaffShift(String id, String name) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeStaffShift.removeWhere((staff) => staff['id'] == id);
    });
    CustomFeedback.showSuccess(
      context,
      "Catatan shift $name berhasil dihapus.",
    );
  }

  // Helper duration formatter (HH:MM:SS)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Handle Logout Confirmation
  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(spacing7),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: const Color(0xFF2A1A0A).withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogoutHandlebar(),
                const SizedBox(height: spacing6),
                const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 32,
                ),
                const SizedBox(height: spacing4),
                Text(
                  "Keluar?",
                  style: lgBold.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: spacing2),
                Text(
                  "Anda harus masuk kembali untuk mengakses\ndashboard Anda",
                  style: xsRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: spacing7),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Batal",
                            style: smBold.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: spacing4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          final prefs = serviceLocator<UserPreference>();
                          prefs.clearData();

                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const RoleSelectorScreen(),
                              transitionDuration: const Duration(
                                milliseconds: 400,
                              ),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Keluar",
                            style: smBold.copyWith(
                              color: const Color(0xFFFF8A8A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + spacing4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: spacing7),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: spacing6,
                      right: spacing6,
                      bottom: bottomPadding + 110,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: spacing7),
                        _buildStatsAndStoreRow(context),
                        const SizedBox(height: spacing8),
                        _buildWeeklyChartSection(),
                        const SizedBox(height: spacing8),
                        if (_isAdmin) ...[
                          _buildActiveStaffShiftSection(),
                          const SizedBox(height: spacing8),
                        ],
                        _buildBestSellersSection(),
                        const SizedBox(height: spacing8),
                        _buildLowStockSection(),
                        const SizedBox(height: spacing8),
                        _buildRecentTransactionsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UI Private Helper Widgets ──

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1207), Color(0xFF2A1A0A), Color(0xFF1A1008)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: spacing6,
        right: spacing5,
        top: spacing5,
      ),
      child: Row(
        children: [
          // Business Avatar Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE27D00), Color(0xFFD06A00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE27D00).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.coffee_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mau Coffee",
                  style: mdBold.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  "Dashboard Bisnis",
                  style: xsRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          // Register Staff Button (+user icon)
          if (_isAdmin) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AdminScanEmployeeScreen(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFFE27D00),
                  size: 18,
                ),
              ),
            ),
          ],
          const SizedBox(width: spacing3),
          // Logout Trigger Button
          GestureDetector(
            onTap: () => _handleLogout(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _welcomeMessage,
          style: const TextStyle(
            fontFamily: 'poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: spacing2),
        Text(
          _welcomeSubtitle,
          style: sRegular.copyWith(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  Widget _buildStatsAndStoreRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildTodaySalesCard()),
        const SizedBox(width: spacing4),
        Expanded(child: _buildStoreStatusCard()),
      ],
    );
  }

  Widget _buildTodaySalesCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(spacing5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Penjualan Hari Ini",
                    style: xxsMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2D8A4E).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF2D8A4E),
                      size: 16,
                    ),
                  ),
                ],
              ),
              Text(
                "Rp 0",
                style: xlBold.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(spacing4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isStoreOpen
                  ? [
                      const Color(0xFF2D8A4E).withValues(alpha: 0.12),
                      const Color(0xFF2D8A4E).withValues(alpha: 0.03),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.03),
                    ],
            ),
            border: Border.all(
              color: _isStoreOpen
                  ? const Color(0xFF2D8A4E).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status Toko",
                    style: xxsMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  _isStoreOpen
                      ? _buildPulseIndicator()
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white38,
                          ),
                        ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isStoreOpen ? _formatDuration(_storeDuration) : "TUTUP",
                    style: lgBold.copyWith(
                      color: _isStoreOpen
                          ? const Color(0xFF2D8A4E)
                          : Colors.white60,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _toggleStoreStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _isStoreOpen
                            ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                            : const Color(0xFFE27D00).withValues(alpha: 0.15),
                        border: Border.all(
                          color: _isStoreOpen
                              ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                              : const Color(0xFFE27D00).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _isStoreOpen ? "Tutup Toko" : "Buka Toko",
                        style: xxxsBold.copyWith(
                          color: _isStoreOpen
                              ? const Color(0xFFFF8A8A)
                              : const Color(0xFFFF9E22),
                        ),
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

  Widget _buildPulseIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2D8A4E),
        boxShadow: [
          BoxShadow(color: Color(0xFF2D8A4E), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PERFORMA MINGGUAN",
          style: xsBold.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(spacing5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap header in a Wrap to avoid overflow on small screens
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tren Penjualan Mingguan",
                              style: smBold.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Menampilkan performa dalam ribuan (K)",
                              style: xxsRegular.copyWith(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: spacing3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(
                            0xFF2D8A4E,
                          ).withValues(alpha: 0.12),
                        ),
                        child: Text(
                          "+15.4%",
                          style: xxsBold.copyWith(
                            color: const Color(0xFF2D8A4E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacing5),
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SalesChartPainter(_weeklySalesData),
                    ),
                  ),
                  const SizedBox(height: spacing3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weeklySalesDays.map((day) {
                      return Flexible(
                        child: Text(
                          day,
                          style: xxsRegular.copyWith(color: Colors.white30),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStaffShiftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SHIFT STAF AKTIF",
          style: xsBold.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing4,
                vertical: spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: _activeStaffShift.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Tidak ada staf aktif yang terdaftar saat ini.",
                          style: sRegular.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeStaffShift.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final staff = _activeStaffShift[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: spacing3,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: staff['avatarColor'].withValues(
                                    alpha: 0.15,
                                  ),
                                  border: Border.all(
                                    color: staff['avatarColor'].withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: staff['avatarColor'],
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: spacing4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff['name'],
                                      style: smBold.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${staff['role']} • Masuk jam ${staff['clockIn']}",
                                      style: xxsRegular.copyWith(
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete shift history record button (Admin control)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.6),
                                  size: 20,
                                ),
                                onPressed: () => _deleteStaffShift(
                                  staff['id'],
                                  staff['name'],
                                ),
                                tooltip: "Hapus Catatan Shift",
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestSellersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRODUK TERLARIS HARI INI",
          style: xsBold.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing4,
                vertical: spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bestSellers.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = _bestSellers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing3),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFE27D00,
                            ).withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.local_cafe_outlined,
                            color: Color(0xFFE27D00),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: spacing4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: smBold.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Total: ${item['sales']}",
                                style: xxsRegular.copyWith(
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: spacing2),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(item['revenue']),
                              style: smBold.copyWith(
                                color: const Color(0xFF2D8A4E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['trend'],
                              style: xxsBold.copyWith(
                                color: const Color(0xFF2D8A4E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PERINGATAN STOK MENIPIS",
          style: xsBold.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing4,
                vertical: spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lowStockItems.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = _lowStockItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing3),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: spacing4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: smBold.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Level stok: ${item['stock']}",
                                style: xxsRegular.copyWith(
                                  color: const Color(0xFFFF8A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: spacing2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            "ISI ULANG",
                            style: xxxsBold.copyWith(
                              color: const Color(0xFFFF8A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TRANSAKSI TERBARU",
          style: xsBold.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing4,
                vertical: spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final trx = _recentTransactions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: spacing3),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF2D8A4E,
                            ).withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: Color(0xFF2D8A4E),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: spacing4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trx['id'],
                                style: smBold.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trx['items'],
                                style: xxsRegular.copyWith(
                                  color: Colors.white38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: spacing2),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(trx['amount']),
                              style: smBold.copyWith(
                                color: const Color(0xFFFF9E22),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trx['time'],
                              style: xxsRegular.copyWith(color: Colors.white30),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutHandlebar() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}

// Custom painter to draw the Weekly Sales line chart dynamically and cleanly
class _SalesChartPainter extends CustomPainter {
  final List<double> dataPoints;
  _SalesChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFE27D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (dataPoints.length - 1);
    final double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * stepX;
      final double y =
          size.height -
          ((dataPoints[i] - minVal) / range) * (size.height - 18) -
          9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE27D00).withValues(alpha: 0.22),
          const Color(0xFFE27D00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = const Color(0xFFE27D00)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF2A1A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * stepX;
      final double y =
          size.height -
          ((dataPoints[i] - minVal) / range) * (size.height - 18) -
          9;
      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
      canvas.drawCircle(Offset(x, y), 4.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
