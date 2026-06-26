import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/utility/rupiah_formatter.dart';
import 'package:maucoffee/ui/widget_sharing/success_dialog.dart';
import 'package:maucoffee/ui/widget_sharing/qris_payment_widget.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_cubit.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_state.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:maucoffee/model/category_model.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/model/order_item_model.dart';

class SalesTransactionScreen extends StatefulWidget {
  const SalesTransactionScreen({super.key});

  @override
  State<SalesTransactionScreen> createState() => _SalesTransactionScreenState();
}

class _SalesTransactionScreenState extends State<SalesTransactionScreen> {
  String _selectedCategoryId = "Semua";
  String _searchQuery = "";
  List<ProductModel> _loadedProducts = [];
  List<CategoryModel> _loadedCategories = [];

  // Cart: Product ID -> Quantity
  final Map<String, int> _cart = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogCubit>().fetchCatalog();
    });
  }

  void _addToCart(ProductModel product) {
    final currentQty = _cart[product.id] ?? 0;

    // Jika stok diset lebih besar dari 0, batasi penjualan sampai batas stok
    if (product.stock > 0 && currentQty >= product.stock) {
      CustomFeedback.showWarning(context, "Mencapai batas stok!");
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _cart[product.id!] = currentQty + 1;
    });
  }

  void _removeFromCart(ProductModel product) {
    final currentQty = _cart[product.id] ?? 0;
    if (currentQty <= 0) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (currentQty == 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id!] = currentQty - 1;
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
      final product = _loadedProducts.firstWhere(
        (p) => p.id == id,
        orElse: () =>
            ProductModel(id: id, categoryId: '', name: 'Unknown', price: 0),
      );
      total += product.price * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          List<ProductModel> products = [];
          List<CategoryModel> categories = [];
          bool isLoading = false;
          String errorMessage = "";

          if (state is CatalogLoaded) {
            products = state.products;
            categories = state.categories;
            _loadedProducts = products;
            _loadedCategories = categories;
          } else if (state is CatalogLoading) {
            products = state.previousProducts ?? [];
            categories = state.previousCategories ?? [];
            _loadedProducts = products;
            _loadedCategories = categories;
            isLoading = products.isEmpty;
          } else if (state is CatalogError) {
            errorMessage = state.message;
          }

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (errorMessage.isNotEmpty && products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: sMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<CatalogCubit>().fetchCatalog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    child: Text(
                      "Coba Lagi",
                      style: sBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtered products list based on search query and category filter
          final filteredList = products.where((product) {
            final matchesCategory =
                _selectedCategoryId == "Semua" ||
                product.categoryId == _selectedCategoryId;
            final matchesSearch = product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return matchesCategory && matchesSearch;
          }).toList();

          return Stack(
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildCategorySelector(categories),
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
                                    bottomPadding +
                                    160, // Clear the checkout bar
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
          );
        },
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
      child: Text("Order Item", style: lgBold.copyWith(color: Colors.white)),
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

  Widget _buildCategorySelector(List<CategoryModel> categories) {
    final List<dynamic> categoryItems = ["Semua", ...categories];

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: spacing3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: spacing6),
        itemCount: categoryItems.length,
        itemBuilder: (context, index) {
          final item = categoryItems[index];
          final String label =
              item is String ? item : (item as CategoryModel).name;
          final String id = item is String ? item : (item as CategoryModel).id!;

          final bool isSelected = _selectedCategoryId == id;
          return Padding(
            padding: const EdgeInsets.only(right: spacing3),
            child: ChoiceChip(
              label: Text(
                label,
                style: sMedium.copyWith(
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: const Color(0xFF2A1A0A).withOpacity(0.50),
              onSelected: (_) {
                setState(() {
                  _selectedCategoryId = id;
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

  Widget _buildProductListItem(ProductModel product) {
    final int cartQty = _cart[product.id] ?? 0;
    final bool isCartFull = product.stock > 0 && cartQty >= product.stock;

    final category = _loadedCategories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => CategoryModel(name: 'General'),
    );
    final String categoryName = category.name.toLowerCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (!isCartFull) {
            _addToCart(product);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: spacing3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF2A1A0A).withOpacity(0.35),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.2,
            ),
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
                  child: product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Text(
                              product.name.isNotEmpty
                                  ? product.name[0].toUpperCase()
                                  : "",
                              style: lgBold.copyWith(color: primaryColor),
                            ),
                          ),
                        )
                      : Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : "",
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
                        "$categoryName • ${currencyFormatter.format(product.price)}",
                        style: xsMedium.copyWith(
                          color:
                              isCartFull ? Colors.redAccent : Colors.white60,
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
                    color: isCartFull
                        ? Colors.grey.withOpacity(0.5)
                        : primaryColor,
                    size: 28,
                  ),
                  onPressed: isCartFull ? null : () => _addToCart(product),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
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
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedPayment = "Cash";
        final totalPrice = _getCartTotal();
        final cashPaidController = TextEditingController(
          text: NumberFormat.decimalPattern('id').format(totalPrice),
        );
        double paidAmount = totalPrice;
        final suggestions = _getSuggestions(totalPrice);

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
                            final product = _loadedProducts.firstWhere(
                              (p) => p.id == id,
                              orElse: () => ProductModel(
                                id: id,
                                categoryId: '',
                                name: 'Unknown',
                                price: 0,
                              ),
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
                      // Input Nama Pembeli
                      Text(
                        "Nama Pembeli (Opsional)",
                        style: xsBold.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacing3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: TextField(
                          controller: nameController,
                          style: sMedium.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Contoh: Budi",
                            hintStyle: sMedium.copyWith(color: Colors.white30),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: spacing4),

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
                      if (selectedPayment == "Cash") ...[
                        const SizedBox(height: spacing4),
                        // Uang Diterima (Pilihan Cepat)
                        Text(
                          "Uang Diterima (Pilihan Cepat)",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: spacing2),
                        Wrap(
                          spacing: spacing2,
                          runSpacing: spacing2,
                          children: suggestions.map((amount) {
                            final bool isSelected = paidAmount == amount;
                            final bool isExact = amount == totalPrice;
                            final String label = isExact
                                ? "Uang Pas"
                                : currencyFormatter.format(amount);

                            return ChoiceChip(
                              label: Text(
                                label,
                                style: xxsBold.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primaryColor,
                              backgroundColor: const Color(
                                0xFF2A1A0A,
                              ).withOpacity(0.50),
                              onSelected: (_) {
                                HapticFeedback.lightImpact();
                                setModalState(() {
                                  paidAmount = amount;
                                  cashPaidController.text =
                                      NumberFormat.decimalPattern(
                                        'id',
                                      ).format(amount);
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: spacing4),

                        // Input nominal manual
                        Text(
                          "Jumlah Tunai Input Manual",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: spacing2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacing3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.04),
                            border: Border.all(
                              color: paidAmount < totalPrice
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Rp",
                                style: smBold.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(width: spacing2),
                              Expanded(
                                child: TextField(
                                  controller: cashPaidController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [RupiahInputFormatter()],
                                  style: smBold.copyWith(color: Colors.white),
                                  onChanged: (val) {
                                    final cleanVal = val.replaceAll('.', '');
                                    final amount =
                                        double.tryParse(cleanVal) ?? 0;
                                    setModalState(() {
                                      paidAmount = amount;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Masukkan nominal tunai",
                                    hintStyle: TextStyle(color: Colors.white30),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Info kembalian / uang kurang
                        if (paidAmount >= totalPrice)
                          Container(
                            padding: const EdgeInsets.all(spacing3),
                            decoration: BoxDecoration(
                              color: (paidAmount - totalPrice) == 0
                                  ? primaryColor.withOpacity(0.1)
                                  : const Color(0xFF2D8A4E).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (paidAmount - totalPrice) == 0
                                    ? primaryColor.withOpacity(0.3)
                                    : const Color(0xFF2D8A4E).withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (paidAmount - totalPrice) == 0
                                      ? Icons.check_circle_rounded
                                      : Icons.monetization_on_rounded,
                                  color: (paidAmount - totalPrice) == 0
                                      ? primaryColor
                                      : const Color(0xFF2D8A4E),
                                  size: 20,
                                ),
                                const SizedBox(width: spacing3),
                                Text(
                                  (paidAmount - totalPrice) == 0
                                      ? "Uang Pas (Tidak ada kembalian)"
                                      : "Kembalian: ${currencyFormatter.format(paidAmount - totalPrice)}",
                                  style: sBold.copyWith(
                                    color: (paidAmount - totalPrice) == 0
                                        ? primaryColor
                                        : const Color(0xFF2D8A4E),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(spacing3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: spacing3),
                                Text(
                                  "Uang pembayaran kurang ${currencyFormatter.format(totalPrice - paidAmount)}",
                                  style: sBold.copyWith(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: spacing6),

                      // Single Confirm button
                      ElevatedButton(
                        onPressed:
                            (selectedPayment == "Cash" &&
                                paidAmount < totalPrice)
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                ); // Close checkout bottom sheet

                                final customerName =
                                    nameController.text.trim().isEmpty
                                    ? "Pelanggan Umum"
                                    : nameController.text.trim();

                                if (selectedPayment == "Cash") {
                                  _processCheckout(
                                    "Cash",
                                    paidAmount: paidAmount,
                                    change: paidAmount - totalPrice,
                                    customerName: customerName,
                                  );
                                } else {
                                  // Show QRIS payment bottom sheet
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        QrisPaymentBottomSheet(
                                          totalPrice: totalPrice,
                                          onConfirm: (imagePath) {
                                            _processCheckout(
                                              "QRIS",
                                              customerName: customerName,
                                              qrisProofPath: imagePath,
                                            );
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

  Future<void> _processCheckout(
    String method, {
    double paidAmount = 0.0,
    double change = 0.0,
    String customerName = "Pelanggan Umum",
    String? qrisProofPath,
  }) async {
    final String trxNum =
        "TRX-${10000 + (DateTime.now().millisecond * 7) % 90000}";

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );

    try {
      String? qrisProofUrl;
      // Upload bukti QRIS jika menggunakan QRIS dan ada path gambarnya
      if (method == "QRIS" && qrisProofPath != null && qrisProofPath.isNotEmpty) {
        final file = File(qrisProofPath);
        final fileName = "qris_${trxNum}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        qrisProofUrl = await serviceLocator<OrderRepository>().uploadQrisProof(file, fileName);
      }

      // Hitung total belanja
      final double totalVal = _getCartTotal();

      // Buat OrderModel
      final order = OrderModel(
        invoiceNumber: trxNum,
        totalAmount: totalVal,
        paymentMethod: method,
        amountPaid: method == "QRIS" ? totalVal : paidAmount,
        change: method == "QRIS" ? 0.0 : change,
        qrisProofUrl: qrisProofUrl,
      );

      // Buat List OrderItemModel
      final List<OrderItemModel> items = [];
      _cart.forEach((id, qty) {
        final product = _loadedProducts.firstWhere(
          (p) => p.id == id,
          orElse: () =>
              ProductModel(id: id, categoryId: '', name: 'Unknown', price: 0),
        );
        items.add(OrderItemModel(
          orderId: '', // Akan diset oleh OrderRepository
          productId: id,
          quantity: qty,
          price: product.price,
        ));
      });

      // Simpan ke Supabase database
      await serviceLocator<OrderRepository>().createOrder(order: order, items: items);

      // Simpan data transaksi ke local HistoryManager agar visualisasi Histori & Keuangan sinkron secara lokal
      final List<TransactionItem> txItems = [];
      _cart.forEach((id, qty) {
        final product = _loadedProducts.firstWhere(
          (p) => p.id == id,
          orElse: () =>
              ProductModel(id: id, categoryId: '', name: 'Unknown', price: 0),
        );
        txItems.add(
          TransactionItem(name: product.name, qty: qty, price: product.price),
        );
      });

      HistoryManager().addTransaction(
        TransactionHistory(
          id: trxNum,
          customerName: customerName,
          dateTime: DateTime.now(),
          totalAmount: totalVal,
          paymentMethod: method,
          items: txItems,
          paidAmount: method == "QRIS" ? totalVal : paidAmount,
          changeAmount: method == "QRIS" ? 0.0 : change,
          qrisProofPath: qrisProofPath,
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
      }

      // Tampilkan dialog sukses
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) =>
              TransactionSuccessDialog(transactionNumber: trxNum, onFinish: () {}),
        ).then((_) {
          if (mounted) {
            setState(() {
              _cart.clear();
            });
            // Refresh Catalog State
            context.read<CatalogCubit>().fetchCatalog();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        CustomFeedback.showError(context, "Transaksi gagal: ${e.toString()}");
      }
    }
  }

  List<double> _getSuggestions(double totalPrice) {
    final double T = totalPrice;
    final List<double> suggestions = [];

    // 1. Selalu sertakan uang pas
    suggestions.add(T);

    // Pecahan uang standar Rupiah
    final List<double> standardNotes = [
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
    ];

    // 2. Tambahkan pecahan standar yang lebih besar dari T
    for (var note in standardNotes) {
      if (note > T) {
        suggestions.add(note);
      }
    }

    // 3. Tambahkan kelipatan bulat terdekat ke atas secara cerdas
    if (T > 0) {
      // Kelipatan 5.000 terdekat ke atas (jika T > 5000)
      if (T > 5000) {
        double next5k = ((T / 5000).ceil() * 5000).toDouble();
        if (next5k > T) suggestions.add(next5k);
      }

      // Kelipatan 10.000 terdekat ke atas
      double next10k = ((T / 10000).ceil() * 10000).toDouble();
      if (next10k > T) suggestions.add(next10k);

      // Kelipatan 20.000 terdekat ke atas
      double next20k = ((T / 20000).ceil() * 20000).toDouble();
      if (next20k > T) suggestions.add(next20k);

      // Kelipatan 50.000 terdekat ke atas (jika T > 20000)
      if (T > 20000) {
        double next50k = ((T / 50000).ceil() * 50000).toDouble();
        if (next50k > T) suggestions.add(next50k);
      }

      // Kelipatan 100.000 terdekat ke atas (jika T > 50000)
      if (T > 50000) {
        double next100k = ((T / 100000).ceil() * 100000).toDouble();
        if (next100k > T) suggestions.add(next100k);
      }
    }

    // Hapus duplikat, filter hanya nilai >= T, dan urutkan
    final List<double> sorted = suggestions
        .toSet()
        .where((val) => val >= T)
        .toList();
    sorted.sort();

    // Batasi maksimal 5 saran nominal agar UI tetap rapi
    return sorted.take(5).toList();
  }
}
