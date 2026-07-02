import 'package:equatable/equatable.dart';
import 'package:maucoffee/model/category_model.dart';
import 'package:maucoffee/model/product_model.dart';
import 'package:maucoffee/model/ingredient_model.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {
  final List<ProductModel>? previousProducts;
  final List<CategoryModel>? previousCategories;
  final List<IngredientModel>? previousIngredients;

  const CatalogLoading({
    this.previousProducts,
    this.previousCategories,
    this.previousIngredients,
  });

  @override
  List<Object?> get props => [
        previousProducts,
        previousCategories,
        previousIngredients,
      ];
}

class CatalogLoaded extends CatalogState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final List<IngredientModel> ingredients;
  final bool isOffline;

  const CatalogLoaded({
    required this.products,
    required this.categories,
    required this.ingredients,
    required this.isOffline,
  });

  @override
  List<Object?> get props => [products, categories, ingredients, isOffline];
}

class CatalogError extends CatalogState {
  final String message;
  final List<ProductModel>? previousProducts;
  final List<CategoryModel>? previousCategories;
  final List<IngredientModel>? previousIngredients;

  const CatalogError(
    this.message, {
    this.previousProducts,
    this.previousCategories,
    this.previousIngredients,
  });

  @override
  List<Object?> get props => [
        message,
        previousProducts,
        previousCategories,
        previousIngredients,
      ];
}
