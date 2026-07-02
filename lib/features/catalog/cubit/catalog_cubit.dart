import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:maucoffee/model/category_model.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:maucoffee/model/ingredient_model.dart';
import 'package:maucoffee/model/stock_log_model.dart';
import 'package:maucoffee/repository/category_repository.dart';
import 'package:maucoffee/repository/product_repository.dart';
import 'package:maucoffee/repository/ingredient_repository.dart';
import 'package:maucoffee/services/offline_storage_service.dart';
import 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final IngredientRepository _ingredientRepository;
  final OfflineStorageService _offlineStorageService;

  CatalogCubit(
    this._productRepository,
    this._categoryRepository,
    this._ingredientRepository,
    this._offlineStorageService,
  ) : super(CatalogInitial());

  void _emitLoading() {
    final current = state;
    if (current is CatalogLoaded) {
      emit(CatalogLoading(
        previousProducts: current.products,
        previousCategories: current.categories,
        previousIngredients: current.ingredients,
      ));
    } else if (current is CatalogLoading) {
      emit(CatalogLoading(
        previousProducts: current.previousProducts,
        previousCategories: current.previousCategories,
        previousIngredients: current.previousIngredients,
      ));
    } else {
      emit(const CatalogLoading());
    }
  }

  void _emitError(String message) {
    final current = state;
    if (current is CatalogLoaded) {
      emit(CatalogError(
        message,
        previousProducts: current.products,
        previousCategories: current.categories,
        previousIngredients: current.ingredients,
      ));
    } else if (current is CatalogLoading) {
      emit(CatalogError(
        message,
        previousProducts: current.previousProducts,
        previousCategories: current.previousCategories,
        previousIngredients: current.previousIngredients,
      ));
    } else if (current is CatalogError) {
      emit(CatalogError(
        message,
        previousProducts: current.previousProducts,
        previousCategories: current.previousCategories,
        previousIngredients: current.previousIngredients,
      ));
    } else {
      emit(CatalogError(message));
    }
  }

  // Memuat data katalog (Produk, Kategori, & Bahan Baku) secara online/offline
  Future<void> fetchCatalog() async {
    debugPrint("CatalogCubit: fetchCatalog called");
    
    // Jika state saat ini masih awal (Initial), coba load cache offline terlebih dahulu secara instan
    // agar data langsung tampil di UI dan tidak memicu spinner layar penuh.
    if (state is CatalogInitial) {
      try {
        final cachedProductsJson = await _offlineStorageService.getProductsCache();
        final cachedCategoriesJson = await _offlineStorageService.getCategoriesCache();
        final cachedIngredientsJson = await _offlineStorageService.getIngredientsCache();

        if (cachedProductsJson.isNotEmpty || cachedCategoriesJson.isNotEmpty || cachedIngredientsJson.isNotEmpty) {
          final products = cachedProductsJson
              .map((json) => ProductModel.fromJson(json))
              .toList();
          final categories = cachedCategoriesJson
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          final ingredients = cachedIngredientsJson
              .map((json) => IngredientModel.fromJson(json))
              .toList();

          debugPrint("CatalogCubit: Initial cache loaded successfully to avoid UI blocking.");
          emit(CatalogLoaded(
            products: products,
            categories: categories,
            ingredients: ingredients,
            isOffline: true,
          ));
        }
      } catch (e) {
        debugPrint("CatalogCubit: Failed to load initial cache: $e");
      }
    }

    _emitLoading();
    try {
      debugPrint("CatalogCubit: loading catalog data from Supabase in parallel...");
      
      // Ambil ketiga data secara paralel dengan timeout 3 detik untuk performa & offline-resilience
      final results = await Future.wait([
        _categoryRepository.getCategories().timeout(const Duration(seconds: 3)),
        _productRepository.getProducts().timeout(const Duration(seconds: 3)),
        _ingredientRepository.getIngredients().timeout(const Duration(seconds: 3)),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final products = results[1] as List<ProductModel>;
      final ingredients = results[2] as List<IngredientModel>;

      debugPrint("CatalogCubit: categories fetched = ${categories.length}");
      debugPrint("CatalogCubit: products fetched = ${products.length}");
      debugPrint("CatalogCubit: ingredients fetched = ${ingredients.length}");

      // Simpan data terbaru ke cache lokal
      final productsJson = products.map((p) => p.toJson()).toList();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      final ingredientsJson = ingredients.map((i) => i.toJson()).toList();

      await _offlineStorageService.saveProductsCache(productsJson);
      await _offlineStorageService.saveCategoriesCache(categoriesJson);
      await _offlineStorageService.saveIngredientsCache(ingredientsJson);

      debugPrint("CatalogCubit: loaded and cached online data successfully.");
      emit(CatalogLoaded(
        products: products,
        categories: categories,
        ingredients: ingredients,
        isOffline: false,
      ));
    } catch (e, stack) {
      debugPrint("CatalogCubit: Error during online fetch: $e");
      debugPrint("CatalogCubit: StackTrace: $stack");
      // Jika terjadi kegagalan koneksi (timeout/network error) di Supabase, fallback ke cache
      try {
        final cachedProductsJson = await _offlineStorageService.getProductsCache();
        final cachedCategoriesJson = await _offlineStorageService.getCategoriesCache();
        final cachedIngredientsJson = await _offlineStorageService.getIngredientsCache();

        if (cachedProductsJson.isNotEmpty || cachedCategoriesJson.isNotEmpty || cachedIngredientsJson.isNotEmpty) {
          final products = cachedProductsJson
              .map((json) => ProductModel.fromJson(json))
              .toList();
          final categories = cachedCategoriesJson
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          final ingredients = cachedIngredientsJson
              .map((json) => IngredientModel.fromJson(json))
              .toList();

          debugPrint("CatalogCubit: Fallback cache loaded. Products: ${products.length}, Categories: ${categories.length}, Ingredients: ${ingredients.length}");
          emit(CatalogLoaded(
            products: products,
            categories: categories,
            ingredients: ingredients,
            isOffline: true,
          ));
          return;
        }
      } catch (innerErr) {
        debugPrint("CatalogCubit: Cache fallback failed: $innerErr");
      }

      _emitError("Gagal memuat katalog: $e");
    }
  }

  // Menambah produk baru (Online Only)
  Future<void> addProduct({
    required String name,
    required double price,
    required String categoryId,
    required int stock,
    required bool isAvailable,
    File? imageFile,
  }) async {
    _emitLoading();
    try {
      String? imageUrl;
      if (imageFile != null) {
        final String fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
        imageUrl = await _productRepository.uploadProductImage(imageFile, fileName);
      }

      final newProduct = ProductModel(
        name: name,
        price: price,
        categoryId: categoryId,
        stock: stock,
        isAvailable: isAvailable,
        imageUrl: imageUrl,
      );

      await _productRepository.addProduct(newProduct);
      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal menambahkan produk: $e");
    }
  }

  // Mengubah produk (Online Only)
  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    required String categoryId,
    required int stock,
    required bool isAvailable,
    String? currentImageUrl,
    File? newImageFile,
  }) async {
    _emitLoading();
    try {
      String? imageUrl = currentImageUrl;
      if (newImageFile != null) {
        final String fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
        imageUrl = await _productRepository.uploadProductImage(newImageFile, fileName);
      }

      final updatedProduct = ProductModel(
        id: id,
        name: name,
        price: price,
        categoryId: categoryId,
        stock: stock,
        isAvailable: isAvailable,
        imageUrl: imageUrl,
      );

      await _productRepository.updateProduct(updatedProduct);
      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal memperbarui produk: $e");
    }
  }

  // Menghapus produk (Online Only)
  Future<void> deleteProduct(String productId) async {
    _emitLoading();
    try {
      await _productRepository.deleteProduct(productId);
      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal menghapus produk: $e");
    }
  }

  // Menambah kategori baru (Online Only)
  Future<void> addCategory(String name) async {
    _emitLoading();
    try {
      await _categoryRepository.addCategory(name);
      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal menambahkan kategori: $e");
    }
  }

  // Menambah bahan baku baru (Online Only)
  Future<void> addIngredient({
    required String name,
    required String category,
    required double stock,
    required String unit,
    required double minStock,
  }) async {
    _emitLoading();
    try {
      final newItem = IngredientModel(
        name: name,
        category: category,
        stock: stock,
        unit: unit,
        minStock: minStock,
      );
      await _ingredientRepository.addIngredient(newItem);

      // Catat log stok ke Supabase
      final log = StockLogModel(
        ingredientName: name,
        category: category,
        adjustedAmount: stock,
        stockBefore: 0.0,
        stockAfter: stock,
        type: "Baru",
      );
      await _ingredientRepository.addStockLog(log);

      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal menambahkan bahan baku: $e");
    }
  }

  // Memperbarui data bahan baku (termasuk restock / update stok) (Online Only)
  Future<void> updateIngredient({
    required String id,
    required String name,
    required String category,
    required double stock,
    required String unit,
    required double minStock,
  }) async {
    double stockBefore = 0.0;
    final current = state;
    if (current is CatalogLoaded) {
      final oldItem = current.ingredients.firstWhere(
        (i) => i.id == id,
        orElse: () => IngredientModel(name: name, category: category),
      );
      stockBefore = oldItem.stock;
    }

    _emitLoading();
    try {
      final updatedItem = IngredientModel(
        id: id,
        name: name,
        category: category,
        stock: stock,
        unit: unit,
        minStock: minStock,
      );
      await _ingredientRepository.updateIngredient(updatedItem);

      // Catat log stok ke Supabase jika nominalnya berubah
      if (stock != stockBefore) {
        final log = StockLogModel(
          ingredientName: name,
          category: category,
          adjustedAmount: (stock - stockBefore).abs(),
          stockBefore: stockBefore,
          stockAfter: stock,
          type: stock > stockBefore ? "Tambah" : "Kurang",
        );
        await _ingredientRepository.addStockLog(log);
      }

      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal memperbarui bahan baku: $e");
    }
  }

  // Menghapus bahan baku (Online Only)
  Future<void> deleteIngredient(String id) async {
    _emitLoading();
    try {
      await _ingredientRepository.deleteIngredient(id);
      await fetchCatalog();
    } catch (e) {
      _emitError("Gagal menghapus bahan baku: $e");
    }
  }
}
