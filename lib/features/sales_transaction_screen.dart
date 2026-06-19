import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/ui/widget_sharing/cash_payment_widget.dart';
import 'package:maucoffee/ui/widget_sharing/success_dialog.dart';
import 'package:maucoffee/ui/widget_sharing/qris_payment_widget.dart';

class ProductDummy {
  final String id;
  final String name;
  final String category;
  final int stock;
  final double price;
  final bool isUnlimited;

  const ProductDummy({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    this.isUnlimited = false,
  });
}

class SalesTransactionScreen extends StatefulWidget {
  const SalesTransactionScreen({super.key});

  @override
  State<SalesTransactionScreen> createState() => _SalesTransactionScreenState();
}

class _SalesTransactionScreenState extends State<SalesTransactionScreen> {
  final List<String> _categories = ["Semua", "add on", "bahan", "bahan seblak"];
  String _selectedCategory = "Semua";
  String _searchQuery = "";

  // Cart: Product ID -> Quantity
  final Map<String, int> _cart = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<ProductDummy> _products = const [
    ProductDummy(
      id: "1",
      name: "Acar Wortel 200 gr",
      category: "bahan",
      stock: 11,
      price: 4000,
    ),
    ProductDummy(
      id: "2",
      name: "Air mineral botol kecil 750 ml",
      category: "add on",
      stock: 17,
      price: 5000,
    ),
    ProductDummy(
      id: "3",
      name: "Almond Crispy Cokelat",
      category: "add on",
      stock: 23,
      price: 55000,
    ),
    ProductDummy(
      id: "4",
      name: "Almond Crispy Keju",
      category: "add on",
      stock: 20,
      price: 55000,
    ),
    ProductDummy(
      id: "5",
      name: "Almond Crispy Matcha",
      category: "add on",
      stock: 38,
      price: 55000,
    ),
    ProductDummy(
      id: "6",
      name: "Americano Ice 340 ml",
      category: "add on",
      stock: 999,
      price: 20000,
      isUnlimited: true,
    ),
    ProductDummy(
      id: "7",
      name: "Antis - Antiseptic Pembersih Tangan 55ml",
      category: "add on",
      stock: 10,
      price: 14000,
    ),
    ProductDummy(
      id: "8",
      name: "Ayam Bakar 1 Ekor",
      category: "bahan seblak",
      stock: 999,
      price: 45500,
      isUnlimited: true,
    ),
    ProductDummy(
      id: "9",
      name: "Ayam Geprek 1 potong",
      category: "bahan seblak",
      stock: 15,
      price: 18000,
    ),
  ];

  void _addToCart(ProductDummy product) {
    if (!product.isUnlimited && product.stock <= 0) {
      CustomFeedback.showWarning(context, "Stok habis!");
      return;
    }

    final currentQty = _cart[product.id] ?? 0;
    if (!product.isUnlimited && currentQty >= product.stock) {
      CustomFeedback.showWarning(context, "Mencapai batas stok!");
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _cart[product.id] = currentQty + 1;
    });
  }

  void _removeFromCart(ProductDummy product) {
    final currentQty = _cart[product.id] ?? 0;
    if (currentQty <= 0) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (currentQty == 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = currentQty - 1;
      }
    });
  }

  int _getCartCount() {
    int total = 0;
    _cart.forEach((_, qty) => total += qty);
    return total;
  }

  double _getCartTotal() {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p.id == id);
      total += product.price * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Filtered products list based on search query and category filter
    final filteredList = _products.where((product) {
      final matchesCategory =
          _selectedCategory == "Semua" || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategorySelector(),
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            "Menu tidak ditemukan",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: spacing6,
                            right: spacing6,
                            top: spacing2,
                            bottom:
                                bottomPadding + 160, // Clear the checkout bar
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final product = filteredList[index];
                            return _buildProductListItem(product);
                          },
                        ),
                ),
              ],
            ),
          ),

          // Floating Checkout Bar
          if (_cart.isNotEmpty)
            Positioned(
              left: spacing4,
              right: spacing4,
              bottom: (bottomPadding > 0 ? bottomPadding : spacing5) + 68,
              child: _buildCheckoutBar(),
            ),
        ],
      ),
    );
  }

  // ── UI Components ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing6,
        vertical: spacing4,
      ),
      child: Text(
        "Transaksi Penjualan",
        style: lgBold.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing6,
        vertical: spacing2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF2A1A0A).withOpacity(0.40),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
            child: TextField(
              style: smMedium.copyWith(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari menu...",
                hintStyle: smRegular.copyWith(
                  color: Colors.white.withOpacity(0.35),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.45),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: spacing3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: spacing6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: spacing3),
            child: ChoiceChip(
              label: Text(
                cat,
                style: sMedium.copyWith(
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: const Color(0xFF2A1A0A).withOpacity(0.50),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(ProductDummy product) {
    final int cartQty = _cart[product.id] ?? 0;
    final bool hasStock = product.isUnlimited || product.stock > 0;
    final String stockText = product.isUnlimited
        ? "Unlimited"
        : "Sisa ${product.stock}";

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: spacing3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2A1A0A).withOpacity(0.35),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(spacing4),
          child: Row(
            children: [
              // Product Image / Initial Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : "",
                  style: lgBold.copyWith(color: primaryColor),
                ),
              ),
              const SizedBox(width: spacing4),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: smBold.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$stockText • ${currencyFormatter.format(product.price)}",
                      style: xsMedium.copyWith(
                        color: hasStock ? Colors.white60 : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: spacing3),

              // Quantity Selector
              if (cartQty > 0) ...[
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  onPressed: () => _removeFromCart(product),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: spacing2),
                  child: Text(
                    "$cartQty",
                    style: smBold.copyWith(color: Colors.white),
                  ),
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: hasStock ? primaryColor : Colors.grey.withOpacity(0.5),
                  size: 28,
                ),
                onPressed: hasStock ? () => _addToCart(product) : null,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    final int totalCount = _getCartCount();
    final double totalPrice = _getCartTotal();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing5,
            vertical: spacing4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF2A1A0A).withOpacity(0.90),
            border: Border.all(
              color: primaryColor.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shopping_basket_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: spacing3),
                  Text(
                    "$totalCount Item | ${currencyFormatter.format(totalPrice)}",
                    style: smBold.copyWith(color: Colors.white),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openCheckoutBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacing5,
                    vertical: spacing3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "LANJUT",
                        style: sBold.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: spacing2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedPayment = "Cash";

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  padding: EdgeInsets.only(
                    left: spacing6,
                    right: spacing6,
                    top: spacing6,
                    bottom: MediaQuery.of(context).viewInsets.bottom + spacing7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A0A).withOpacity(0.95),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Checkout Detail",
                        style: mdBold.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: spacing2),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: spacing2),

                      // Cart items list
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final id = _cart.keys.elementAt(index);
                            final qty = _cart[id]!;
                            final product = _products.firstWhere(
                              (p) => p.id == id,
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: spacing2,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${product.name} (x$qty)",
                                      style: sMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(
                                      product.price * qty,
                                    ),
                                    style: sBold.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: spacing2),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: spacing3),

                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: smMedium.copyWith(color: Colors.white70),
                          ),
                          Text(
                            currencyFormatter.format(_getCartTotal()),
                            style: mdBold.copyWith(color: primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: spacing5),

                      // Payment Methods Title
                      Text(
                        "Metode Pembayaran",
                        style: xsBold.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: spacing4),

                      // Payment Method Selector Grid
                      Row(
                        children: [
                          // Cash Option Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedPayment = "Cash";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: spacing3,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedPayment == "Cash"
                                      ? primaryColor.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPayment == "Cash"
                                        ? primaryColor
                                        : Colors.white.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      color: selectedPayment == "Cash"
                                          ? primaryColor
                                          : Colors.white60,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Tunai (Cash)",
                                      style: xsBold.copyWith(
                                        color: selectedPayment == "Cash"
                                            ? primaryColor
                                            : Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: spacing4),

                          // QRIS Option Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedPayment = "QRIS";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: spacing3,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedPayment == "QRIS"
                                      ? primaryColor.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPayment == "QRIS"
                                        ? primaryColor
                                        : Colors.white.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: selectedPayment == "QRIS"
                                          ? primaryColor
                                          : Colors.white60,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "QRIS",
                                      style: xsBold.copyWith(
                                        color: selectedPayment == "QRIS"
                                            ? primaryColor
                                            : Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: spacing6),

                      // Single Confirm button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close checkout bottom sheet

                          if (selectedPayment == "Cash") {
                            // Show cash payment bottom sheet
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CashPaymentBottomSheet(
                                totalPrice: _getCartTotal(),
                                onConfirm: (paid, change) {
                                  _processCheckout(
                                    "Cash",
                                    paidAmount: paid,
                                    change: change,
                                  );
                                },
                              ),
                            );
                          } else {
                            // Show QRIS payment bottom sheet
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => QrisPaymentBottomSheet(
                                totalPrice: _getCartTotal(),
                                onConfirm: (imagePath) {
                                  _processCheckout("QRIS");
                                },
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: spacing4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Konfirmasi & Bayar",
                          style: sBold.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _processCheckout(String method, {double paidAmount = 0.0, double change = 0.0}) {
    final String trxNum =
        "TRX-${10000 + (DateTime.now().millisecond * 7) % 90000}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransactionSuccessDialog(
        transactionNumber: trxNum,
        onFinish: () {
          setState(() {
            _cart.clear(); // Clear Cart
          });
          CustomFeedback.showSuccess(
            context,
            "Transaksi berhasil disimpan!",
          );
        },
      ),
    );
  }
}
