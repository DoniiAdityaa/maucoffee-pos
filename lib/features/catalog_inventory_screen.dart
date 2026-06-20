import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/data/history_manager.dart';

// Model untuk Bahan Baku
class IngredientItem {
  final String id;
  final String name;
  final String category;
  double stock;
  final String unit;
  final double minStock;

  IngredientItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    required this.minStock,
  });
}

// Model untuk Menu Penjualan
class ProductItem {
  final String id;
  final String name;
  final String category;
  final double price;
  int stock;
  final bool isUnlimited;

  ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.isUnlimited = false,
  });
}

class CatalogInventoryScreen extends StatefulWidget {
  const CatalogInventoryScreen({super.key});

  @override
  State<CatalogInventoryScreen> createState() => _CatalogInventoryScreenState();
}

class _CatalogInventoryScreenState extends State<CatalogInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedIngredientCategory = "Semua";
  String _selectedProductCategory = "Semua";

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Kategori bahan baku
  final List<String> _ingredientCategories = [
    "Semua",
    "Bubuk & Kopi",
    "Susu & Creamer",
    "Sirup",
    "Pemanis",
  ];

  // Kategori menu penjualan
  final List<String> _productCategories = [
    "Semua",
    "Coffee",
    "Non-Coffee",
    "Pastry",
    "add on",
  ];

  // Data Dummy Menu Penjualan
  final List<ProductItem> _products = [
    ProductItem(
      id: "p1",
      name: "Es Kopi Susu Aren",
      category: "Coffee",
      price: 18000,
      stock: 100,
      isUnlimited: true,
    ),
    ProductItem(
      id: "p2",
      name: "Americano Ice",
      category: "Coffee",
      price: 15000,
      stock: 80,
      isUnlimited: true,
    ),
    ProductItem(
      id: "p3",
      name: "Matcha Latte",
      category: "Non-Coffee",
      price: 20000,
      stock: 50,
    ),
    ProductItem(
      id: "p4",
      name: "Red Velvet Ice",
      category: "Non-Coffee",
      price: 20000,
      stock: 45,
    ),
    ProductItem(
      id: "p5",
      name: "Croissant Almond",
      category: "Pastry",
      price: 25000,
      stock: 8,
    ),
    ProductItem(
      id: "p6",
      name: "Cinnamon Roll",
      category: "Pastry",
      price: 22000,
      stock: 12,
    ),
    ProductItem(
      id: "p7",
      name: "Ekstra Shot Espresso",
      category: "add on",
      price: 5000,
      stock: 200,
      isUnlimited: true,
    ),
  ];

  // Data Dummy Bahan Baku sesuai request user
  final List<IngredientItem> _ingredients = [
    IngredientItem(
      id: "1",
      name: "bubuk kopi",
      category: "Bubuk & Kopi",
      stock: 5,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "2",
      name: "bubuk gula aren",
      category: "Pemanis",
      stock: 3,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "3",
      name: "bubuk creamer",
      category: "Susu & Creamer",
      stock: 1,
      unit: "pcs",
      minStock: 1,
    ), // Menipis
    IngredientItem(
      id: "4",
      name: "matcha",
      category: "Bubuk & Kopi",
      stock: 4,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "5",
      name: "susu uht",
      category: "Susu & Creamer",
      stock: 6,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "6",
      name: "susu kaleng",
      category: "Susu & Creamer",
      stock: 0,
      unit: "pcs",
      minStock: 1,
    ), // Habis
    IngredientItem(
      id: "7",
      name: "red velvet",
      category: "Bubuk & Kopi",
      stock: 2,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "8",
      name: "sirup vanilla",
      category: "Sirup",
      stock: 1,
      unit: "pcs",
      minStock: 1,
    ), // Menipis
    IngredientItem(
      id: "9",
      name: "taro",
      category: "Bubuk & Kopi",
      stock: 1,
      unit: "pcs",
      minStock: 1,
    ), // Menipis
    IngredientItem(
      id: "10",
      name: "sirup gula aren",
      category: "Sirup",
      stock: 4,
      unit: "pcs",
      minStock: 1,
    ),
    IngredientItem(
      id: "11",
      name: "sirup butterscotch",
      category: "Sirup",
      stock: 3,
      unit: "pcs",
      minStock: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Menghitung status stok bahan baku (0 = habis, 1 = menipis, >= 2 = aman)
  Map<String, int> _getIngredientStats() {
    int safeCount = 0;
    int warningCount = 0;
    int emptyCount = 0;

    for (var ing in _ingredients) {
      if (ing.stock == 0) {
        emptyCount++;
      } else if (ing.stock == 1) {
        warningCount++;
      } else {
        safeCount++;
      }
    }

    return {"safe": safeCount, "warning": warningCount, "empty": emptyCount};
  }

  // Menampilkan dialog tambah bahan baku baru
  void _showAddIngredientDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = _ingredientCategories[1]; // default Bubuk & Kopi

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF2A1A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(spacing5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Tambah Bahan Baku Baru",
                    style: mdBold.copyWith(color: Colors.white),
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  // Input Nama Bahan
                  Text(
                    "Nama Bahan Baku",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(nameController, "Contoh: bubuk cokelat"),
                  const SizedBox(height: spacing4),

                  // Dropdown Kategori
                  Text(
                    "Kategori",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: spacing3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        dropdownColor: const Color(0xFF2A1A0A),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                        ),
                        style: sMedium.copyWith(color: Colors.white),
                        onChanged: (String? val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                        items: _ingredientCategories
                            .where((cat) => cat != "Semua")
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing4),

                  // Input Stok Awal (Satuan otomatis 'pcs')
                  Text(
                    "Stok Awal (pcs)",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(stockController, "0", isNumber: true),
                  const SizedBox(height: spacing5),

                  // Button Simpan
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final stock = double.tryParse(stockController.text) ?? 0;

                      if (name.isEmpty) {
                        CustomFeedback.showError(
                          context,
                          "Nama bahan baku tidak boleh kosong!",
                        );
                        return;
                      }

                      final newId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      setState(() {
                        _ingredients.add(
                          IngredientItem(
                            id: newId,
                            name: name.toLowerCase(),
                            category: selectedCategory,
                            stock: stock,
                            unit: "pcs",
                            minStock: 1,
                          ),
                        );
                      });

                      // Catat ke HistoryManager
                      HistoryManager().addStockLog(
                        StockHistory(
                          id: "LOG-$newId",
                          ingredientName: name.toLowerCase(),
                          category: selectedCategory,
                          adjustedAmount: stock,
                          stockBefore: 0,
                          stockAfter: stock,
                          type: "Baru",
                          dateTime: DateTime.now(),
                        ),
                      );

                      Navigator.pop(context);
                      CustomFeedback.showSuccess(
                        context,
                        "Bahan baku berhasil ditambahkan!",
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: spacing3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Simpan Bahan",
                      style: sBold.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog sesuaikan stok (Restock)
  void _showRestockDialog(IngredientItem item) {
    final adjustController = TextEditingController();
    bool isAdd = true; // true untuk tambah stok, false untuk kurangi stok

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF2A1A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(spacing5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Restock / Sesuaikan Stok",
                  style: mdBold.copyWith(color: Colors.white),
                ),
                Text(
                  item.name,
                  style: xsMedium.copyWith(
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Divider(color: Colors.white10, height: 20),

                // Pilihan Tambah / Kurang
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isAdd = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isAdd
                                ? primaryColor.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAdd ? primaryColor : Colors.white10,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: isAdd ? primaryColor : Colors.white60,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Tambah",
                                  style: sBold.copyWith(
                                    color: isAdd
                                        ? primaryColor
                                        : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: spacing3),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isAdd = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isAdd
                                ? Colors.redAccent.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isAdd ? Colors.redAccent : Colors.white10,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_rounded,
                                  color: !isAdd
                                      ? Colors.redAccent
                                      : Colors.white60,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Kurang",
                                  style: sBold.copyWith(
                                    color: !isAdd
                                        ? Colors.redAccent
                                        : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: spacing4),

                Text(
                  "Jumlah Nominal (pcs)",
                  style: xsBold.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                _customTextField(adjustController, "0", isNumber: true),
                const SizedBox(height: spacing5),

                // Button Konfirmasi
                ElevatedButton(
                  onPressed: () {
                    final double adjustVal =
                        double.tryParse(adjustController.text) ?? 0.0;
                    if (adjustVal <= 0) {
                      CustomFeedback.showError(
                        context,
                        "Jumlah harus lebih besar dari 0!",
                      );
                      return;
                    }

                    final stockBefore = item.stock;
                    final stockAfter = isAdd
                        ? stockBefore + adjustVal
                        : (stockBefore - adjustVal).clamp(0.0, double.infinity);

                    setState(() {
                      item.stock = stockAfter;
                    });

                    // Catat ke HistoryManager
                    HistoryManager().addStockLog(
                      StockHistory(
                        id: "LOG-${DateTime.now().millisecondsSinceEpoch}",
                        ingredientName: item.name,
                        category: item.category,
                        adjustedAmount: adjustVal,
                        stockBefore: stockBefore,
                        stockAfter: stockAfter,
                        type: isAdd ? "Tambah" : "Kurang",
                        dateTime: DateTime.now(),
                      ),
                    );

                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    CustomFeedback.showSuccess(
                      context,
                      "Stok ${item.name} berhasil diperbarui!",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdd ? primaryColor : Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: spacing3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isAdd ? "Konfirmasi Tambah" : "Konfirmasi Kurang",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // navigation background will be visible
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Screen
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing6,
                vertical: spacing2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Katalog & Inventory",
                    style: lgBold.copyWith(color: Colors.white),
                  ),

                  // Action Button
                  GestureDetector(
                    onTap: () {
                      if (_tabController.index == 0) {
                        CustomFeedback.showInfo(
                          context,
                          "Gunakan Dashboard Admin untuk mengedit Menu.",
                        );
                      } else {
                        _showAddIngredientDialog();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor, width: 1),
                  ),
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: sBold,
                  unselectedLabelStyle: sMedium,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "Menu Penjualan"),
                    Tab(text: "Bahan Baku (Inventory)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: spacing3),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildProductTab(), _buildIngredientTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Menu Penjualan ──
  Widget _buildProductTab() {
    final filtered = _products.where((p) {
      return _selectedProductCategory == "Semua" ||
          p.category == _selectedProductCategory;
    }).toList();

    return Column(
      children: [
        // Category Chips Row (Desain disamakan dengan Transaksi Penjualan)
        Container(
          height: 52,
          margin: const EdgeInsets.symmetric(vertical: spacing2),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: spacing6),
            itemCount: _productCategories.length,
            itemBuilder: (context, index) {
              final cat = _productCategories[index];
              final bool isSelected = _selectedProductCategory == cat;
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
                      _selectedProductCategory = cat;
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
        ),
        const SizedBox(height: spacing3),

        // Product List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState("Tidak ada menu yang sesuai.")
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: spacing6,
                    right: spacing6,
                    bottom: 100, // padding for floating glass navigation bar
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: spacing3),
                      padding: const EdgeInsets.all(spacing4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: sBold.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.category,
                                      style: xxxsMedium.copyWith(
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            currencyFormatter.format(product.price),
                            style: sBold.copyWith(color: primaryColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Tab 2: Bahan Baku (Inventory) ──
  Widget _buildIngredientTab() {
    final stats = _getIngredientStats();
    final filtered = _ingredients.where((i) {
      return _selectedIngredientCategory == "Semua" ||
          i.category == _selectedIngredientCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ringkasan Indikator Stok (Statistics Grid Cards)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing6,
            vertical: spacing2,
          ),
          child: Row(
            children: [
              _buildStatCard(
                "Total",
                _ingredients.length.toString(),
                Colors.blueAccent,
              ),
              const SizedBox(width: spacing2),
              _buildStatCard(
                "Menipis",
                stats["warning"].toString(),
                const Color(0xFFFF9E22),
              ),
              const SizedBox(width: spacing2),
              _buildStatCard(
                "Habis",
                stats["empty"].toString(),
                Colors.redAccent,
              ),
            ],
          ),
        ),

        // Category Chips Row (Desain disamakan dengan Transaksi Penjualan)
        Container(
          height: 52,
          margin: const EdgeInsets.symmetric(vertical: spacing2),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: spacing6),
            itemCount: _ingredientCategories.length,
            itemBuilder: (context, index) {
              final cat = _ingredientCategories[index];
              final bool isSelected = _selectedIngredientCategory == cat;
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
                      _selectedIngredientCategory = cat;
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
        ),
        const SizedBox(height: spacing3),

        // Ingredient List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState("Tidak ada bahan baku yang sesuai.")
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: spacing6,
                    right: spacing6,
                    bottom: 100, // padding for floating glass navigation bar
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final bool isEmpty = item.stock == 0;
                    final bool isWarning =
                        item.stock == 1; // Aturan baru: 1 pcs = menipis

                    Color statusColor = const Color(
                      0xFF2D8A4E,
                    ); // Aman (cozy green)
                    String statusText = "Aman";
                    if (isEmpty) {
                      statusColor = Colors.redAccent;
                      statusText = "Habis";
                    } else if (isWarning) {
                      statusColor = const Color(0xFFFF9E22);
                      statusText = "Menipis";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: spacing3),
                      padding: const EdgeInsets.all(spacing4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWarning
                              ? const Color(0xFFFF9E22).withOpacity(0.2)
                              : isEmpty
                              ? Colors.redAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: sBold.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: xxxsMedium.copyWith(
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Batas Minimal: 1 ${item.unit}",
                                      style: xxsMedium.copyWith(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Stock Indicator & Action Button
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${item.stock.toStringAsFixed(0)} ${item.unit}",
                                    style: sBold.copyWith(
                                      color: isEmpty
                                          ? Colors.redAccent
                                          : isWarning
                                          ? const Color(0xFFFF9E22)
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.2),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: xxxsBold.copyWith(
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: spacing3),
                              // Restock Action Button
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_business_rounded,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                onPressed: () => _showRestockDialog(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _customTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: spacing3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: sMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: spacing3,
          horizontal: spacing4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: xxsBold.copyWith(color: Colors.white, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(value, style: mdBold.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white12,
            size: 48,
          ),
          const SizedBox(height: spacing2),
          Text(text, style: sMedium.copyWith(color: Colors.white30)),
        ],
      ),
    );
  }
}
