import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/utility/rupiah_formatter.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_cubit.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_state.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:maucoffee/model/category_model.dart';
import 'package:maucoffee/model/ingredient_model.dart';

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
  String? _selectedStockFilter;
  final Set<String> _dismissedIngredientIds = {};
  final Set<String> _dismissedProductIds = {};

  bool get _isAdmin {
    final userPrefs = serviceLocator<UserPreference>();
    return userPrefs.getLoginRole() == 'admin';
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Kategori bahan baku
  final List<String> _ingredientCategories = ["Semua", "Bubuk & Kopi", "Sirup"];

  // // kategory menu penjualan
  // final List<String> _menuCategories = ['Semua', 'coffee', 'milk', 'tea'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("CatalogInventoryScreen: Calling fetchCatalog from initState");
      context.read<CatalogCubit>().fetchCatalog();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Menghitung status stok bahan baku (0 = habis, <= minStock = menipis, > minStock = aman)
  Map<String, int> _getIngredientStats(List<IngredientModel> ingredients) {
    int safeCount = 0;
    int warningCount = 0;
    int emptyCount = 0;

    for (var ing in ingredients) {
      if (ing.stock == 0) {
        emptyCount++;
      } else if (ing.stock <= ing.minStock) {
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

                      context.read<CatalogCubit>().addIngredient(
                        name: name.toLowerCase(),
                        category: selectedCategory,
                        stock: stock,
                        unit: "pcs",
                        minStock: 1.0,
                      );

                      Navigator.pop(context);
                      CustomFeedback.showSuccess(
                        context,
                        "Bahan baku '${name}' sedang ditambahkan...",
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
  void _showRestockDialog(IngredientModel item, bool isOffline) {
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

                    if (isOffline) {
                      CustomFeedback.showError(
                        context,
                        "Tidak dapat menyesuaikan stok saat offline.",
                      );
                      return;
                    }

                    final stockBefore = item.stock;
                    final stockAfter = isAdd
                        ? stockBefore + adjustVal
                        : (stockBefore - adjustVal).clamp(0.0, double.infinity);

                    context.read<CatalogCubit>().updateIngredient(
                      id: item.id!,
                      name: item.name,
                      category: item.category,
                      stock: stockAfter,
                      unit: item.unit,
                      minStock: item.minStock,
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

  // Dialog tambah menu penjualan baru
  void _showAddProductDialog(List<CategoryModel> dbCategories) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    String? selectedCategoryId = dbCategories.isNotEmpty
        ? dbCategories[0].id
        : null;
    String? selectedImagePath;

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
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Tambah Menu Penjualan Baru",
                    style: mdBold.copyWith(color: Colors.white),
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  // Input Nama Menu
                  Text(
                    "Nama Menu",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(
                    nameController,
                    "Contoh: Es Kopi Susu Gula Aren",
                  ),
                  const SizedBox(height: spacing4),

                  // Input Harga Menu
                  Text(
                    "Harga (Rp)",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(
                    priceController,
                    "Contoh: 18.000",
                    isNumber: true,
                    inputFormatters: [RupiahInputFormatter()],
                  ),
                  const SizedBox(height: spacing5),

                  // Dropdown Kategori
                  Text(
                    "Kategori",
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId,
                        dropdownColor: const Color(0xFF2A1A0A),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                        ),
                        style: sMedium.copyWith(color: Colors.white),
                        onChanged: (String? val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategoryId = val;
                            });
                          }
                        },
                        items: dbCategories.map<DropdownMenuItem<String>>((
                          CategoryModel cat,
                        ) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing5),

                  // Image Upload Field
                  _buildImageUploadField(
                    context: context,
                    currentImagePath: selectedImagePath,
                    onImagePicked: (path) {
                      selectedImagePath = path;
                    },
                    setDialogState: setDialogState,
                  ),
                  const SizedBox(height: spacing6),

                  // Button Simpan
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final price =
                          double.tryParse(
                            priceController.text.replaceAll('.', '').trim(),
                          ) ??
                          0;

                      if (name.isEmpty) {
                        CustomFeedback.showError(
                          context,
                          "Nama menu tidak boleh kosong!",
                        );
                        return;
                      }

                      if (price <= 0) {
                        CustomFeedback.showError(
                          context,
                          "Harga menu harus lebih besar dari 0!",
                        );
                        return;
                      }

                      if (selectedCategoryId == null) {
                        CustomFeedback.showError(
                          context,
                          "Kategori belum dipilih!",
                        );
                        return;
                      }

                      // Memanggil Cubit untuk menambahkan produk
                      context.read<CatalogCubit>().addProduct(
                        name: name,
                        price: price,
                        categoryId: selectedCategoryId!,
                        stock: 0,
                        isAvailable: true,
                        imageFile: selectedImagePath != null
                            ? File(selectedImagePath!)
                            : null,
                      );

                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                      CustomFeedback.showSuccess(
                        context,
                        "Menu '$name' sedang disimpan ke server...",
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
                      "Simpan Menu",
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

  // Dialog edit menu penjualan
  void _showEditProductDialog(
    ProductModel product,
    List<CategoryModel> dbCategories,
  ) {
    final nameController = TextEditingController(text: product.name);
    final priceFormatter = NumberFormat.decimalPattern('id');
    final priceController = TextEditingController(
      text: priceFormatter.format(product.price),
    );

    String? selectedCategoryId =
        dbCategories.any((cat) => cat.id == product.categoryId)
        ? product.categoryId
        : (dbCategories.isNotEmpty ? dbCategories[0].id : null);

    String? selectedImagePath = product.imageUrl;

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
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Edit Menu Penjualan",
                    style: mdBold.copyWith(color: Colors.white),
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  // Input Nama Menu
                  Text(
                    "Nama Menu",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(nameController, "Nama Menu"),
                  const SizedBox(height: spacing4),

                  // Input Harga Menu
                  Text(
                    "Harga (Rp)",
                    style: xsBold.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  _customTextField(
                    priceController,
                    "Harga Menu",
                    isNumber: true,
                    inputFormatters: [RupiahInputFormatter()],
                  ),
                  const SizedBox(height: spacing5),

                  // Dropdown Kategori
                  Text(
                    "Kategori",
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId,
                        dropdownColor: const Color(0xFF2A1A0A),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                        ),
                        style: sMedium.copyWith(color: Colors.white),
                        onChanged: (String? val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategoryId = val;
                            });
                          }
                        },
                        items: dbCategories.map<DropdownMenuItem<String>>((
                          CategoryModel cat,
                        ) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing5),

                  // Image Upload Field
                  _buildImageUploadField(
                    context: context,
                    currentImagePath: selectedImagePath,
                    onImagePicked: (path) {
                      selectedImagePath = path;
                    },
                    setDialogState: setDialogState,
                  ),
                  const SizedBox(height: spacing6),

                  // Button Actions
                  Row(
                    children: [
                      // Tombol Simpan Perubahan
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final price =
                                double.tryParse(
                                  priceController.text
                                      .replaceAll('.', '')
                                      .trim(),
                                ) ??
                                0;

                            if (name.isEmpty) {
                              CustomFeedback.showError(
                                context,
                                "Nama menu tidak boleh kosong!",
                              );
                              return;
                            }

                            if (price <= 0) {
                              CustomFeedback.showError(
                                context,
                                "Harga menu harus lebih besar dari 0!",
                              );
                              return;
                            }

                            if (selectedCategoryId == null) {
                              CustomFeedback.showError(
                                context,
                                "Kategori belum dipilih!",
                              );
                              return;
                            }

                            final bool hasNewImage =
                                selectedImagePath != null &&
                                !selectedImagePath!.startsWith('http');

                            // Memanggil Cubit untuk memperbarui produk
                            context.read<CatalogCubit>().updateProduct(
                              id: product.id!,
                              name: name,
                              price: price,
                              categoryId: selectedCategoryId!,
                              stock: product.stock,
                              isAvailable: product.isAvailable,
                              currentImageUrl: hasNewImage
                                  ? null
                                  : selectedImagePath,
                              newImageFile: hasNewImage
                                  ? File(selectedImagePath!)
                                  : null,
                            );

                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();
                            CustomFeedback.showSuccess(
                              context,
                              "Perubahan sedang disimpan...",
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: spacing3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Simpan",
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
        ),
      ),
    );
  }

  // Dialog konfirmasi hapus menu
  Future<bool?> _showDeleteProductConfirmation(ProductModel product) {
    return showDialog<bool>(
      context: context,
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
                "Hapus Menu Penjualan?",
                style: mdBold.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                "Apakah Anda yakin ingin menghapus '${product.name}' dari katalog penjualan?",
                style: sMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: spacing5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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

  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: spacing3),
      padding: const EdgeInsets.symmetric(horizontal: spacing5),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.redAccent.withValues(alpha: 0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Hapus", style: sBold.copyWith(color: Colors.redAccent)),
          const SizedBox(width: spacing3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogCubit, CatalogState>(
      listener: (context, state) {
        if (state is CatalogError) {
          CustomFeedback.showError(context, state.message);
        } else if (state is CatalogLoaded) {
          setState(() {
            _dismissedIngredientIds.clear();
            _dismissedProductIds.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // navigation background will be visible
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, state) {
              debugPrint("CatalogInventoryScreen: BlocBuilder state = $state");

              List<ProductModel>? products;
              List<CategoryModel>? categories;
              List<IngredientModel>? ingredients;
              bool isOffline = false;
              bool isLoading = false;

              if (state is CatalogLoaded) {
                products = state.products;
                categories = state.categories;
                ingredients = state.ingredients;
                isOffline = state.isOffline;
              } else if (state is CatalogLoading) {
                products = state.previousProducts;
                categories = state.previousCategories;
                ingredients = state.previousIngredients;
                isLoading = true;
              } else if (state is CatalogError) {
                products = state.previousProducts;
                categories = state.previousCategories;
                ingredients = state.previousIngredients;
              }

              final productsList = products ?? <ProductModel>[];
              final categoriesList = categories ?? <CategoryModel>[];
              final ingredientsList = ingredients ?? <IngredientModel>[];

              // Jika terjadi error dan data kosong
              if ((products == null ||
                      categories == null ||
                      ingredients == null) &&
                  state is CatalogError) {
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
                        state.message,
                        style: sMedium.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
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

              return Column(
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
                        Row(
                          children: [
                            Text(
                              "Katalog & Inventory",
                              style: lgBold.copyWith(color: Colors.white),
                            ),
                            if (isOffline) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  "Offline",
                                  style: xxxsBold.copyWith(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Action Button
                        if (_isAdmin && !isOffline)
                          GestureDetector(
                            onTap: () {
                              if (_tabController.index == 0) {
                                _showAddProductDialog(categoriesList);
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
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
                      children: [
                        _buildProductTab(
                          productsList,
                          categoriesList,
                          isOffline,
                          isLoading,
                        ),
                        _buildIngredientTab(
                          ingredientsList,
                          isOffline,
                          isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Menu Penjualan ──
  Widget _buildProductTab(
    List<ProductModel> products,
    List<CategoryModel> categories,
    bool isOffline,
    bool isLoading,
  ) {
    if (isLoading && products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final List<String> productCategories = [
      "Semua",
      ...categories.map((c) => c.name),
    ];

    final filtered = products.where((p) {
      if (_dismissedProductIds.contains(p.id)) return false;
      if (_selectedProductCategory == "Semua") return true;
      final cat = categories.firstWhere(
        (c) => c.name.toLowerCase() == _selectedProductCategory.toLowerCase(),
        orElse: () => CategoryModel(name: ''),
      );
      return p.categoryId == cat.id;
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
            itemCount: productCategories.length,
            itemBuilder: (context, index) {
              final cat = productCategories[index];
              final bool isSelected =
                  _selectedProductCategory.toLowerCase() == cat.toLowerCase();
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
                    final itemWidget = GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isOffline) {
                          CustomFeedback.showError(
                            context,
                            "Tidak dapat mengedit produk saat offline.",
                          );
                        } else {
                          _showEditProductDialog(product, categories);
                        }
                      },
                      child: Container(
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
                          children: [
                            // Kotakan Gambar Produk
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: primaryColor,
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                              Icons.coffee_rounded,
                                              color: primaryColor.withOpacity(
                                                0.6,
                                              ),
                                              size: 24,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.coffee_rounded,
                                      color: primaryColor.withOpacity(0.6),
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: spacing4),
                            // Informasi Produk
                            Expanded(
                              child: Column(
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          categories
                                              .firstWhere(
                                                (c) =>
                                                    c.id == product.categoryId,
                                                orElse: () => CategoryModel(
                                                  name: 'General',
                                                ),
                                              )
                                              .name,
                                          style: xxxsMedium.copyWith(
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: spacing2),
                            // Harga Produk
                            Text(
                              currencyFormatter.format(product.price),
                              style: sBold.copyWith(color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    );

                    return Dismissible(
                      key: Key(product.id ?? ''),
                      direction: _isAdmin && !isOffline
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      secondaryBackground: _buildDismissibleBackground(),
                      background: const SizedBox(),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        final confirm = await _showDeleteProductConfirmation(
                          product,
                        );
                        return confirm ?? false;
                      },
                      onDismissed: (direction) {
                        setState(() {
                          _dismissedProductIds.add(product.id!);
                        });
                        context.read<CatalogCubit>().deleteProduct(product.id!);
                        CustomFeedback.showSuccess(
                          context,
                          "Menu '${product.name}' sedang dihapus...",
                        );
                      },
                      child: itemWidget,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<bool?> _showDeleteIngredientConfirmation(IngredientModel item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1A0A),
        title: Text(
          "Hapus Bahan Baku",
          style: mdBold.copyWith(color: Colors.white),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus '${item.name}' dari inventory?",
          style: sMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: sBold.copyWith(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Hapus",
              style: sBold.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTab(
    List<IngredientModel> ingredients,
    bool isOffline,
    bool isLoading,
  ) {
    if (isLoading && ingredients.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final stats = _getIngredientStats(ingredients);
    final filtered = ingredients.where((i) {
      if (_dismissedIngredientIds.contains(i.id)) return false;

      // Filter kategori
      final matchesCategory =
          _selectedIngredientCategory == "Semua" ||
          i.category.toLowerCase() == _selectedIngredientCategory.toLowerCase();
      if (!matchesCategory) return false;

      // Filter stok (Opsi B)
      if (_selectedStockFilter == 'empty') {
        return i.stock == 0;
      } else if (_selectedStockFilter == 'warning') {
        return i.stock <= i.minStock && i.stock > 0;
      }

      return true;
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
                label: "Total",
                value: ingredients.length.toString(),
                color: Colors.blueAccent,
                isSelected: _selectedStockFilter == null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedStockFilter = null;
                  });
                },
              ),
              const SizedBox(width: spacing2),
              _buildStatCard(
                label: "Menipis",
                value: stats["warning"].toString(),
                color: const Color(0xFFFF9E22),
                isSelected: _selectedStockFilter == 'warning',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_selectedStockFilter == 'warning') {
                      _selectedStockFilter = null;
                    } else {
                      _selectedStockFilter = 'warning';
                    }
                  });
                },
              ),
              const SizedBox(width: spacing2),
              _buildStatCard(
                label: "Habis",
                value: stats["empty"].toString(),
                color: Colors.redAccent,
                isSelected: _selectedStockFilter == 'empty',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_selectedStockFilter == 'empty') {
                      _selectedStockFilter = null;
                    } else {
                      _selectedStockFilter = 'empty';
                    }
                  });
                },
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
              final bool isSelected =
                  _selectedIngredientCategory.toLowerCase() ==
                  cat.toLowerCase();
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
                        item.stock <= item.minStock && item.stock > 0;

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

                    final itemWidget = GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showRestockDialog(item, isOffline);
                      },
                      child: Container(
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                        "Batas Minimal: ${item.minStock.toStringAsFixed(0)} ${item.unit}",
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    return Dismissible(
                      key: Key(item.id ?? ''),
                      direction: _isAdmin && !isOffline
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      secondaryBackground: _buildDismissibleBackground(),
                      background: const SizedBox(),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        final confirm = await _showDeleteIngredientConfirmation(
                          item,
                        );
                        return confirm ?? false;
                      },
                      onDismissed: (direction) {
                        setState(() {
                          _dismissedIngredientIds.add(item.id!);
                        });
                        context.read<CatalogCubit>().deleteIngredient(item.id!);
                        CustomFeedback.showSuccess(
                          context,
                          "Bahan baku '${item.name}' sedang dihapus...",
                        );
                      },
                      child: itemWidget,
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters:
            inputFormatters ??
            (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
        style: sMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: spacing3,
            horizontal: spacing4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.08)
                : Colors.white.withOpacity(0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.15),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: xxsBold.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: mdBold.copyWith(color: color)),
            ],
          ),
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

  Widget _buildImageUploadField({
    required BuildContext context,
    required String? currentImagePath,
    required Function(String?) onImagePicked,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Foto Produk", style: xsBold.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final ImagePicker picker = ImagePicker();
            HapticFeedback.lightImpact();

            final source = await showModalBottomSheet<ImageSource>(
              context: context,
              backgroundColor: const Color(0xFF2A1A0A),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(spacing5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Pilih Sumber Foto",
                      style: mdBold.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: spacing4),
                    ListTile(
                      leading: const Icon(
                        Icons.camera_alt_rounded,
                        color: primaryColor,
                      ),
                      title: Text(
                        "Kamera",
                        style: sMedium.copyWith(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.photo_library_rounded,
                        color: primaryColor,
                      ),
                      title: Text(
                        "Galeri",
                        style: sMedium.copyWith(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            );

            if (source != null) {
              try {
                final XFile? pickedFile = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (pickedFile != null) {
                  setDialogState(() {
                    onImagePicked(pickedFile.path);
                  });
                }
              } catch (e) {
                debugPrint("Error picking image: $e");
              }
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                style: BorderStyle.solid,
              ),
            ),
            child: currentImagePath != null && currentImagePath.isNotEmpty
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: currentImagePath.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: currentImagePath,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                )
                              : Image.file(
                                  File(currentImagePath),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setDialogState(() {
                              onImagePicked(null);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: primaryColor.withOpacity(0.6),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Unggah Foto Produk",
                          style: xsMedium.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
