import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/auth/admin_scan_employee_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/features/absensi/cubit/absensi_cubit.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/home/staff_list/admin_staff_management_screen.dart';
import 'package:maucoffee/navigation/navigation.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/repository/ingredient_repository.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_cubit.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_state.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maucoffee/services/offline_storage_service.dart';

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

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final timeFormatter = DateFormat('HH:mm');

  // Best Selling Items
  List<Map<String, dynamic>> _bestSellers = [];

  // Low Stock Items
  List<Map<String, dynamic>> _lowStockItems = [];

  // Recent Transactions Preview
  List<Map<String, dynamic>> _recentTransactions = [];

  // Weekly sales chart data points
  List<double> _weeklySalesData = [0, 0, 0, 0, 0, 0, 0];
  List<String> _weeklySalesDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  bool _isLoadingDashboard = false;
  String _weeklyGrowthLabel = "0%";
  Color _weeklyGrowthColor = Colors.white30;
  double _todaySalesAmount = 0.0;
  bool _isOfflineMode = false;
  String _lastSyncTime = "";

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _loadUserSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
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

  Future<void> _fetchDashboardData() async {
    if (_isLoadingDashboard) return;

    setState(() {
      _isLoadingDashboard = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any(
        (r) => r != ConnectivityResult.none,
      );

      if (!isOnline) {
        await _loadOfflineDashboardCache();
        return;
      }

      // 1. Refresh & pastikan Catalog loaded
      await context.read<CatalogCubit>().fetchCatalog();
      final catalogState = context.read<CatalogCubit>().state;
      List<ProductModel> products = [];
      if (catalogState is CatalogLoaded) {
        products = catalogState.products;
      }

      // 2. Load orders dari OrderRepository (14 hari terakhir untuk Weekly Performance)
      final orders = await serviceLocator<OrderRepository>().getOrderHistory();
      final nowLocal = DateTime.now();

      // Saring orders untuk 14 hari terakhir (menggunakan timezone lokal agar akurat)
      final ordersLocal = orders.map((o) {
        return OrderModel(
          id: o.id,
          adminId: o.adminId,
          invoiceNumber: o.invoiceNumber,
          totalAmount: o.totalAmount,
          paymentMethod: o.paymentMethod,
          amountPaid: o.amountPaid,
          change: o.change,
          qrisProofUrl: o.qrisProofUrl,
          cashierId: o.cashierId,
          createdAt: o.createdAt?.toLocal(),
        );
      }).toList();

      // ── PERFORMA MINGGUAN (7 Hari Terakhir vs 7 Hari Sebelumnya) ──
      final List<DateTime> last7Days = List.generate(7, (index) {
        return DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day,
        ).subtract(Duration(days: 6 - index));
      });

      final List<double> newWeeklySalesData = [];
      final List<String> newWeeklySalesDays = [];
      double totalThisWeek = 0;

      for (var day in last7Days) {
        double dayTotal = 0;
        for (var order in ordersLocal) {
          if (order.createdAt != null &&
              order.createdAt!.year == day.year &&
              order.createdAt!.month == day.month &&
              order.createdAt!.day == day.day) {
            dayTotal += order.totalAmount;
          }
        }
        // Konversi ke ribuan (K)
        newWeeklySalesData.add(dayTotal / 1000.0);
        newWeeklySalesDays.add(_getDayLabel(day.weekday));
        totalThisWeek += dayTotal;
      }

      // Hitung total minggu sebelumnya (hari ke 7-13 ago)
      double totalLastWeek = 0;
      final startLastWeek = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
      ).subtract(const Duration(days: 13));
      final endLastWeek = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
      ).subtract(const Duration(days: 7));

      for (var order in ordersLocal) {
        if (order.createdAt != null) {
          final orderDate = DateTime(
            order.createdAt!.year,
            order.createdAt!.month,
            order.createdAt!.day,
          );
          if (orderDate.isAtSameMomentAs(startLastWeek) ||
              orderDate.isAtSameMomentAs(endLastWeek) ||
              (orderDate.isAfter(startLastWeek) &&
                  orderDate.isBefore(
                    endLastWeek.add(const Duration(days: 1)),
                  ))) {
            totalLastWeek += order.totalAmount;
          }
        }
      }

      double growthPercent = 0;
      if (totalLastWeek > 0) {
        growthPercent = ((totalThisWeek - totalLastWeek) / totalLastWeek) * 100;
      } else if (totalThisWeek > 0) {
        growthPercent = 100;
      }

      String growthLabel = "0%";
      Color growthColor = Colors.white30;
      if (growthPercent > 0) {
        growthLabel = "+${growthPercent.toStringAsFixed(1)}%";
        growthColor = const Color(0xFF2D8A4E);
      } else if (growthPercent < 0) {
        growthLabel = "${growthPercent.toStringAsFixed(1)}%";
        growthColor = const Color(0xFFFF6B6B);
      } else {
        growthLabel = "0%";
        growthColor = Colors.white30;
      }

      // ── DETEKSI TRANSAKSI HARI INI ──
      final todayOrders = ordersLocal.where((order) {
        if (order.createdAt == null) return false;
        return order.createdAt!.year == nowLocal.year &&
            order.createdAt!.month == nowLocal.month &&
            order.createdAt!.day == nowLocal.day;
      }).toList();

      // Hitung total Penjualan Hari Ini
      double todaySalesSum = 0;
      for (var order in todayOrders) {
        todaySalesSum += order.totalAmount;
      }

      // ── TRANSAKSI TERBARU HARI INI (Maksimal 5 Transaksi) ──
      final recentOrders = todayOrders.take(5).toList();
      final recentOrderIds = recentOrders
          .map((o) => o.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final allRecentItems = await serviceLocator<OrderRepository>()
          .getOrderItemsForOrders(recentOrderIds);

      final List<Map<String, dynamic>> newRecentTransactions = [];
      for (var order in recentOrders) {
        final orderItems = allRecentItems
            .where((item) => item.orderId == order.id)
            .toList();

        String itemsPreview = "";
        if (orderItems.isEmpty) {
          itemsPreview = "Manual / Pemasukan Lain";
        } else {
          itemsPreview = orderItems
              .map((item) {
                final product = products.firstWhere(
                  (p) => p.id == item.productId,
                  orElse: () => ProductModel(
                    id: item.productId,
                    categoryId: '',
                    name: item.notes ?? 'Item',
                    price: item.price,
                  ),
                );
                return "${product.name} x${item.quantity}";
              })
              .join(", ");
        }

        final timeStr = order.createdAt != null
            ? DateFormat('HH:mm').format(order.createdAt!)
            : '--:--';

        newRecentTransactions.add({
          'id': order.invoiceNumber,
          'items': itemsPreview,
          'time': timeStr,
          'amount': order.totalAmount,
        });
      }

      // ── PRODUK TERLARIS HARI INI (Maksimal 3 Produk) ──
      final todayOrderIds = todayOrders
          .map((o) => o.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final todayItems = await serviceLocator<OrderRepository>()
          .getOrderItemsForOrders(todayOrderIds);

      final Map<String, int> productQuantities = {};
      final Map<String, double> productRevenues = {};

      for (var item in todayItems) {
        final product = products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductModel(
            id: item.productId,
            categoryId: '',
            name: item.notes ?? 'Menu Lain',
            price: item.price,
          ),
        );
        final productName = product.name;

        productQuantities[productName] =
            (productQuantities[productName] ?? 0) + item.quantity;
        productRevenues[productName] =
            (productRevenues[productName] ?? 0.0) +
            (item.price * item.quantity);
      }

      final List<Map<String, dynamic>> bestSellersComputed = [];
      productQuantities.forEach((productName, qty) {
        final revenue = productRevenues[productName] ?? 0.0;
        bestSellersComputed.add({
          'name': productName,
          'sales': '$qty Cups',
          'revenue': revenue,
          'trend': 'Terlaris',
        });
      });

      bestSellersComputed.sort((a, b) {
        final int qtyA = int.parse((a['sales'] as String).split(' ')[0]);
        final int qtyB = int.parse((b['sales'] as String).split(' ')[0]);
        return qtyB.compareTo(qtyA);
      });

      final newBestSellers = bestSellersComputed.take(3).toList();

      // ── PERINGATAN STOK MENIPIS (Maksimal 5 Bahan Baku) ──
      final ingredients = await serviceLocator<IngredientRepository>()
          .getIngredients();
      final List<Map<String, dynamic>> newLowStockItems = [];
      for (var ingredient in ingredients) {
        if (ingredient.stock <= ingredient.minStock) {
          newLowStockItems.add({
            'name': ingredient.name,
            'stock':
                '${ingredient.stock.toStringAsFixed(1)} ${ingredient.unit} tersisa',
          });
        }
      }
      final limitedLowStockItems = newLowStockItems.take(5).toList();

      final cacheData = {
        'weeklySalesData': newWeeklySalesData,
        'weeklySalesDays': newWeeklySalesDays,
        'weeklyGrowthLabel': growthLabel,
        'weeklyGrowthColor': growthColor.value,
        'recentTransactions': newRecentTransactions,
        'bestSellers': newBestSellers,
        'lowStockItems': limitedLowStockItems,
        'todaySalesAmount': todaySalesSum,
        'lastSyncTime': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
      };
      await serviceLocator<OfflineStorageService>().saveDashboardCache(
        cacheData,
      );

      setState(() {
        _weeklySalesData = newWeeklySalesData;
        _weeklySalesDays = newWeeklySalesDays;
        _weeklyGrowthLabel = growthLabel;
        _weeklyGrowthColor = growthColor;
        _recentTransactions = newRecentTransactions;
        _bestSellers = newBestSellers;
        _lowStockItems = limitedLowStockItems;
        _todaySalesAmount = todaySalesSum;
        _isOfflineMode = false;
        _lastSyncTime = "";
        _isLoadingDashboard = false;
      });
    } catch (e) {
      await _loadOfflineDashboardCache();
      if (mounted) {
        CustomFeedback.showInfo(
          context,
          "Terhubung offline. Menampilkan data cache.",
        );
      }
    }
  }

  Future<void> _loadOfflineDashboardCache() async {
    try {
      final cache = await serviceLocator<OfflineStorageService>()
          .getDashboardCache();
      if (cache != null) {
        setState(() {
          _weeklySalesData = List<double>.from(
            cache['weeklySalesData'] ?? [0, 0, 0, 0, 0, 0, 0],
          );
          _weeklySalesDays = List<String>.from(
            cache['weeklySalesDays'] ??
                ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
          );
          _weeklyGrowthLabel = cache['weeklyGrowthLabel'] ?? "0%";
          _weeklyGrowthColor = Color(
            cache['weeklyGrowthColor'] ?? Colors.white30.value,
          );
          _recentTransactions = List<Map<String, dynamic>>.from(
            cache['recentTransactions'] ?? [],
          );
          _bestSellers = List<Map<String, dynamic>>.from(
            cache['bestSellers'] ?? [],
          );
          _lowStockItems = List<Map<String, dynamic>>.from(
            cache['lowStockItems'] ?? [],
          );
          _todaySalesAmount =
              (cache['todaySalesAmount'] as num?)?.toDouble() ?? 0.0;
          _isOfflineMode = true;
          _lastSyncTime = cache['lastSyncTime'] ?? "";
          _isLoadingDashboard = false;
        });
      } else {
        setState(() {
          _isOfflineMode = true;
          _lastSyncTime = "";
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      setState(() {
        _isOfflineMode = true;
        _isLoadingDashboard = false;
      });
    }
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Sen';
      case 2:
        return 'Sel';
      case 3:
        return 'Rab';
      case 4:
        return 'Kam';
      case 5:
        return 'Jum';
      case 6:
        return 'Sab';
      case 7:
        return 'Min';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Handle Logout Confirmation
  // Future<void> _handleLogout(BuildContext context) async {
  //   HapticFeedback.mediumImpact();

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => ClipRRect(
  //       borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  //         child: Container(
  //           padding: const EdgeInsets.all(spacing7),
  //           decoration: BoxDecoration(
  //             borderRadius: const BorderRadius.vertical(
  //               top: Radius.circular(24),
  //             ),
  //             color: const Color(0xFF2A1A0A).withValues(alpha: 0.95),
  //             border: Border(
  //               top: BorderSide(
  //                 color: Colors.white.withValues(alpha: 0.1),
  //                 width: 1,
  //               ),
  //             ),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               _buildLogoutHandlebar(),
  //               const SizedBox(height: spacing6),
  //               const Icon(
  //                 Icons.logout_rounded,
  //                 color: Color(0xFFFF6B6B),
  //                 size: 32,
  //               ),
  //               const SizedBox(height: spacing4),
  //               Text(
  //                 "Keluar?",
  //                 style: lgBold.copyWith(
  //                   color: Colors.white,
  //                   letterSpacing: -0.3,
  //                 ),
  //               ),
  //               const SizedBox(height: spacing2),
  //               Text(
  //                 "Anda harus masuk kembali untuk mengakses\ndashboard Anda",
  //                 style: xsRegular.copyWith(
  //                   color: Colors.white.withValues(alpha: 0.4),
  //                   height: 1.5,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: spacing7),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: GestureDetector(
  //                       onTap: () => Navigator.pop(ctx),
  //                       child: Container(
  //                         height: 50,
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(14),
  //                           color: Colors.white.withValues(alpha: 0.06),
  //                           border: Border.all(
  //                             color: Colors.white.withValues(alpha: 0.08),
  //                           ),
  //                         ),
  //                         alignment: Alignment.center,
  //                         child: Text(
  //                           "Batal",
  //                           style: smBold.copyWith(
  //                             color: Colors.white.withValues(alpha: 0.5),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: spacing4),
  //                   Expanded(
  //                     child: GestureDetector(
  //                       onTap: () {
  //                         Navigator.pop(ctx);
  //                         final prefs = serviceLocator<UserPreference>();
  //                         prefs.clearData();

  //                         Navigator.pushAndRemoveUntil(
  //                           context,
  //                           PageRouteBuilder(
  //                             pageBuilder:
  //                                 (context, animation, secondaryAnimation) =>
  //                                     const RoleSelectorScreen(),
  //                             transitionDuration: const Duration(
  //                               milliseconds: 400,
  //                             ),
  //                             transitionsBuilder:
  //                                 (
  //                                   context,
  //                                   animation,
  //                                   secondaryAnimation,
  //                                   child,
  //                                 ) {
  //                                   return FadeTransition(
  //                                     opacity: animation,
  //                                     child: child,
  //                                   );
  //                                 },
  //                           ),
  //                           (route) => false,
  //                         );
  //                       },
  //                       child: Container(
  //                         height: 50,
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(14),
  //                           color: const Color(
  //                             0xFFFF6B6B,
  //                           ).withValues(alpha: 0.15),
  //                           border: Border.all(
  //                             color: const Color(
  //                               0xFFFF6B6B,
  //                             ).withValues(alpha: 0.3),
  //                           ),
  //                         ),
  //                         alignment: Alignment.center,
  //                         child: Text(
  //                           "Keluar",
  //                           style: smBold.copyWith(
  //                             color: const Color(0xFFFF8A8A),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: MediaQuery.of(ctx).padding.bottom + spacing4),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
                if (_isOfflineMode) ...[
                  const SizedBox(height: spacing2),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: spacing6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacing4,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9E22).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF9E22).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: Color(0xFFFF9E22),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _lastSyncTime.isNotEmpty
                                ? "Mode Offline - Sinkronisasi terakhir: $_lastSyncTime"
                                : "Mode Offline - Koneksi terputus",
                            style: xxsMedium.copyWith(
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: spacing7),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        context.read<AbsensiCubit>().fetchActiveShifts(),
                        _fetchDashboardData(),
                      ]);
                    },
                    color: primaryColor,
                    backgroundColor: const Color(0xFF2A1A0A),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            _buildActiveStaffShiftSection(context),
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
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_maucoffee.png',
                width: 22,
                height: 22,
                fit: BoxFit.cover,
              ),
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
                        const AdminStaffManagementScreen(),
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
                  Icons.people_alt_rounded,
                  color: Color(0xFFE27D00),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: spacing3),
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
    return _buildTodaySalesCard();
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
                currencyFormatter.format(_todaySalesAmount),
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
                          color: _weeklyGrowthColor.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          _weeklyGrowthLabel,
                          style: xxsBold.copyWith(color: _weeklyGrowthColor),
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

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'cashier':
      case 'kasir':
        return const Color(0xFFE27D00);
      case 'admin':
      case 'owner':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFE27D00); // Default to orange
    }
  }

  void _deleteStaffShiftDialog(
    BuildContext context,
    String shiftId,
    String staffName,
  ) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Hapus Catatan Shift?",
          style: mdBold.copyWith(color: Colors.white),
        ),
        content: Text(
          "Anda akan menghapus paksa catatan shift kerja aktif untuk $staffName. Aksi ini tidak dapat dibatalkan.",
          style: sRegular.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Batal",
              style: sMedium.copyWith(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AbsensiCubit>().deleteShift(shiftId: shiftId);
              CustomFeedback.showSuccess(
                context,
                "Catatan shift $staffName berhasil dihapus.",
              );
            },
            child: Text(
              "Hapus",
              style: sBold.copyWith(color: const Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStaffShiftSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SHIFT STAF AKTIF",
              style: xsBold.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.only(
                left: spacing4,
                right: spacing4,
                top: 0,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: BlocBuilder<AbsensiCubit, AbsensiState>(
                builder: (context, state) {
                  if (state.status == AbsensiStatus.loading &&
                      state.activeShifts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state.status == AbsensiStatus.error) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Gagal memuat data: ${state.errorMessage}",
                          style: sRegular.copyWith(
                            color: const Color(0xFFFF6B6B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final activeShifts = state.activeShifts;

                  if (activeShifts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Tidak ada staf aktif yang terdaftar saat ini.",
                          style: sRegular.copyWith(color: Colors.white38),
                        ),
                      ),
                    );
                  }

                  final displayedShifts = activeShifts.take(3).toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedShifts.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final shift = displayedShifts[index];
                      final roleColor = _getRoleColor(shift.employeeRole);
                      var clockInTime = shift.clockIn.toLocal();
                      if (clockInTime.isAfter(DateTime.now())) {
                        clockInTime = clockInTime.subtract(
                          clockInTime.timeZoneOffset,
                        );
                      }
                      final formattedTime = timeFormatter.format(clockInTime);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: spacing3),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: roleColor.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: roleColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: roleColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: spacing4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shift.employeeName ?? "Staf",
                                    style: smBold.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${shift.employeeRole ?? 'Kasir'} • Masuk jam $formattedTime",
                                    style: xxsRegular.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // if (shift.id != null)
                            //   IconButton(
                            //     icon: Icon(
                            //       Icons.delete_outline_rounded,
                            //       color: const Color(
                            //         0xFFFF6B6B,
                            //       ).withValues(alpha: 0.6),
                            //       size: 20,
                            //     ),
                            //     onPressed: () {
                            //       _deleteStaffShiftDialog(
                            //         context,
                            //         shift.id!,
                            //         shift.employeeName ?? "Staf",
                            //       );
                            //     },
                            //     tooltip: "Hapus Catatan Shift",
                            //   ),
                          ],
                        ),
                      );
                    },
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
              padding: const EdgeInsets.only(
                left: spacing4,
                right: spacing4,
                top: 0,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: _bestSellers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Belum ada order hari ini.",
                          style: sRegular.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bestSellers.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _bestSellers[index];
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
                                      style: smBold.copyWith(
                                        color: Colors.white70,
                                      ),
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
        GestureDetector(
          onTap: () {
            final mainNav = context
                .findAncestorStateOfType<MainNavigationState>();
            mainNav?.setIndex(6); // Catalog/Inventaris screen
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PERINGATAN STOK MENIPIS",
                style: xsBold.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Lihat Detail",
                    style: xxsMedium.copyWith(color: const Color(0xFFFF6B6B)),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 11),
            child: Container(
              padding: const EdgeInsets.only(
                left: spacing4,
                right: spacing4,
                top: 0,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: _lowStockItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Semua stok bahan baku aman.",
                          style: sRegular.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lowStockItems.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _lowStockItems[index];
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
                                      style: smBold.copyWith(
                                        color: Colors.white70,
                                      ),
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
        GestureDetector(
          onTap: () {
            final mainNav = context
                .findAncestorStateOfType<MainNavigationState>();
            mainNav?.setIndex(2); // History/Aktivitas screen
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TRANSAKSI TERBARU",
                style: xsBold.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Lihat Detail",
                    style: xxsMedium.copyWith(color: const Color(0xFF2D8A4E)),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF2D8A4E),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: spacing4),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.only(
                left: spacing4,
                right: spacing4,
                top: 0,
                bottom: 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: _recentTransactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: spacing5),
                      child: Center(
                        child: Text(
                          "Belum ada transaksi saat ini.",
                          style: sRegular.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final trx = _recentTransactions[index];
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
                                      style: smBold.copyWith(
                                        color: Colors.white70,
                                      ),
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
                                    style: xxsRegular.copyWith(
                                      color: Colors.white30,
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
