import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/model/category_model.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/model/order_item_model.dart';
import 'package:maucoffee/repository/category_repository.dart';
import 'package:maucoffee/repository/product_repository.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  EmployeeModel? _currentEmployee;
  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  String _selectedCategoryId = 'all';
  final Map<String, int> _cart = {}; // productId -> quantity
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = serviceLocator<UserPreference>();
      _currentEmployee = prefs.getEmployee();

      final categoryRepo = serviceLocator<CategoryRepository>();
      final productRepo = serviceLocator<ProductRepository>();

      final adminId = _currentEmployee?.adminId;
      final loadedCategories = await categoryRepo.getCategories(adminId: adminId);
      final loadedProducts = await productRepo.getProducts(adminId: adminId);

      setState(() {
        _categories = loadedCategories;
        _allProducts = loadedProducts;
        _filteredProducts = loadedProducts;
      });
    } catch (e) {
      debugPrint("Gagal memuat data POS: $e");
      if (mounted) {
        CustomFeedback.showError(context, "Gagal memuat data: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == 'all') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product.categoryId == categoryId)
            .toList();
      }
    });
  }

  void _addToCart(ProductModel product) {
    if (product.stock <= 0) {
      CustomFeedback.showWarning(context, "Stok produk kosong!");
      return;
    }

    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.stock) {
      CustomFeedback.showWarning(context, "Jumlah melebihi stok yang tersedia!");
      return;
    }

    setState(() {
      _cart[product.id!] = currentQty + 1;
    });
  }

  void _removeFromCart(ProductModel product) {
    final currentQty = _cart[product.id] ?? 0;
    if (currentQty <= 0) return;

    setState(() {
      if (currentQty == 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id!] = currentQty - 1;
      }
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    _cart.forEach((productId, qty) {
      final product = _allProducts.firstWhere((p) => p.id == productId);
      total += product.price * qty;
    });
    return total;
  }

  int _calculateTotalItems() {
    int total = 0;
    _cart.forEach((_, qty) => total += qty);
    return total;
  }

  Future<void> _handleLogout() async {
    final prefs = serviceLocator<UserPreference>();
    prefs.clearData();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
        (route) => false,
      );
    }
  }

  void _openCheckoutBottomSheet() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double totalPrice = _calculateTotalPrice();
            final int totalItems = _calculateTotalItems();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: spacing6,
                right: spacing6,
                top: spacing6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Checkout Detail",
                    style: mdBold.copyWith(color: textDarkPrimary),
                  ),
                  const Divider(),
                  const SizedBox(height: spacing2),

                  // List Item Keranjang
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final productId = _cart.keys.elementAt(index);
                        final qty = _cart[productId]!;
                        final product = _allProducts.firstWhere(
                          (p) => p.id == productId,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: spacing2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: sBold.copyWith(
                                        color: textDarkPrimary,
                                      ),
                                    ),
                                    Text(
                                      currencyFormatter.format(product.price),
                                      style: xsRegular.copyWith(
                                        color: textDarkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: errorColor,
                                    ),
                                    onPressed: () {
                                      _removeFromCart(product);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                  Text(
                                    "$qty",
                                    style: sBold.copyWith(
                                      color: textDarkPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: primaryColor,
                                    ),
                                    onPressed: () {
                                      _addToCart(product);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(),
                  const SizedBox(height: spacing2),

                  // Ringkasan Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total ($totalItems items)",
                        style: sMedium.copyWith(color: textDarkSecondary),
                      ),
                      Text(
                        currencyFormatter.format(totalPrice),
                        style: mdBold.copyWith(color: primaryColor),
                      ),
                    ],
                  ),

                  const SizedBox(height: spacing6),

                  // Button Bayar (Cash / QRIS)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _processPayment(context, 'Cash', totalPrice),
                          icon: const Icon(Icons.money, color: primaryColor),
                          label: Text(
                            "Bayar Cash",
                            style: sBold.copyWith(color: primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(
                              vertical: spacing4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                borderRadius200,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: spacing4),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _processPayment(context, 'QRIS', totalPrice),
                          icon: const Icon(Icons.qr_code, color: Colors.white),
                          label: Text(
                            "Bayar QRIS",
                            style: sBold.copyWith(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: spacing4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                borderRadius200,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacing8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    String method,
    double totalAmount,
  ) async {
    // 1. Ambil nomor invoice acak
    final invoiceNum = "INV-${DateTime.now().millisecondsSinceEpoch}";

    // 2. Tampilkan dialog sukses transaksi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius300),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: successColor, size: 28),
            const SizedBox(width: spacing3),
            Text(
              "Transaksi Sukses!",
              style: mdBold.copyWith(color: textDarkPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Invoice: $invoiceNum",
              style: xsBold.copyWith(color: textDarkSecondary),
            ),
            const SizedBox(height: spacing2),
            Text(
              "Metode Pembayaran: $method",
              style: sRegular.copyWith(color: textDarkPrimary),
            ),
            Text(
              "Total Pembayaran: ${currencyFormatter.format(totalAmount)}",
              style: sBold.copyWith(color: textDarkPrimary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx); // Tutup dialog
              Navigator.pop(context); // Tutup bottom sheet

              // Simpan ke database Supabase
              try {
                final orderRepo = serviceLocator<OrderRepository>();

                final order = OrderModel(
                  invoiceNumber: invoiceNum,
                  adminId: _currentEmployee?.adminId,
                  totalAmount: totalAmount,
                  paymentMethod: method,
                  amountPaid: totalAmount,
                  change: 0,
                  cashierId: _currentEmployee?.id,
                );

                final List<OrderItemModel> items = [];
                _cart.forEach((productId, qty) {
                  final product = _allProducts.firstWhere(
                    (p) => p.id == productId,
                  );
                  items.add(
                    OrderItemModel(
                      orderId: '', // Diisi otomatis di repository
                      productId: productId,
                      quantity: qty,
                      price: product.price,
                    ),
                  );
                });

                await orderRepo.createOrder(order: order, items: items);

                // Clear cart & Reload stock data
                setState(() {
                  _cart.clear();
                });
                _loadInitialData();

                if (context.mounted) {
                  CustomFeedback.showSuccess(context, "Data transaksi berhasil disimpan ke Supabase!");
                }
              } catch (e) {
                if (context.mounted) {
                  CustomFeedback.showError(context, "Gagal menyimpan transaksi ke database: $e");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text("Selesai", style: sBold.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = _calculateTotalPrice();
    final int totalItems = _calculateTotalItems();

    return Scaffold(
      backgroundColor: black50,
      appBar: AppBar(
        title: Text(
          "Mau Coffee Cashier",
          style: mdBold.copyWith(color: textDarkPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: errorColor),
            onPressed: _handleLogout,
            tooltip: "Keluar",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Karyawan
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacing6,
                    vertical: spacing4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: primaryColor),
                      ),
                      const SizedBox(width: spacing4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat Bekerja!",
                              style: xxsRegular.copyWith(
                                color: textDarkSecondary,
                              ),
                            ),
                            Text(
                              "${_currentEmployee?.name ?? 'Karyawan'} (${_currentEmployee?.role ?? 'Staff'})",
                              style: sBold.copyWith(color: textDarkPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Kategori Selector
                Container(
                  height: 56,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: spacing2),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: spacing6),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      final bool isAll = index == 0;
                      final String catId = isAll
                          ? 'all'
                          : _categories[index - 1].id!;
                      final String catName = isAll
                          ? 'Semua'
                          : _categories[index - 1].name;
                      final bool isSelected = _selectedCategoryId == catId;

                      return Padding(
                        padding: const EdgeInsets.only(right: spacing3),
                        child: ChoiceChip(
                          label: Text(
                            catName,
                            style: sMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : textDarkPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: black100,
                          onSelected: (_) => _filterProducts(catId),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              borderRadius200,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),

                // Daftar Produk Grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text("Tidak ada produk dalam kategori ini"),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(spacing6),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: spacing4,
                                mainAxisSpacing: spacing4,
                              ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final int cartQty = _cart[product.id] ?? 0;
                            final bool hasStock = product.stock > 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  borderRadius300,
                                ),
                                border: Border.all(color: black200, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Gambar / Inisial Nama (Placeholder Premium)
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.05),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(
                                                borderRadius300,
                                              ),
                                            ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        product.name.isNotEmpty
                                            ? product.name[0]
                                            : "",
                                        style: lBold.copyWith(
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Detail Produk
                                  Padding(
                                    padding: const EdgeInsets.all(spacing3),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: sBold.copyWith(
                                            color: textDarkPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: spacing1),
                                        Text(
                                          currencyFormatter.format(
                                            product.price,
                                          ),
                                          style: xsBold.copyWith(
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: spacing1),
                                        Text(
                                          "Stok: ${product.stock}",
                                          style: xxsRegular.copyWith(
                                            color: hasStock
                                                ? textDarkSecondary
                                                : errorColor,
                                          ),
                                        ),
                                        const SizedBox(height: spacing3),

                                        // Tombol Aksi Keranjang
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (cartQty > 0) ...[
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle,
                                                  color: errorColor,
                                                  size: 28,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    _removeFromCart(product),
                                              ),
                                              Text(
                                                "$cartQty",
                                                style: sBold.copyWith(
                                                  color: textDarkPrimary,
                                                ),
                                              ),
                                            ],
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: hasStock
                                                    ? primaryColor
                                                    : Colors.grey,
                                                size: 28,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: hasStock
                                                  ? () => _addToCart(product)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      // Floating Cart Summary Bar
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(spacing6),
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(borderRadius300),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openCheckoutBottomSheet,
                    borderRadius: BorderRadius.circular(borderRadius300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: spacing5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_basket_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: spacing3),
                              Text(
                                "$totalItems Item | ${currencyFormatter.format(totalPrice)}",
                                style: sBold.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Checkout",
                                style: sBold.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: spacing1),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
