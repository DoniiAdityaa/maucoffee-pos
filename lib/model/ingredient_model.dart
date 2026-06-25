import 'package:json_annotation/json_annotation.dart';

part 'ingredient_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IngredientModel {
  final String? id;
  final String? adminId;
  final String name;
  final String category;
  final double stock;
  final String unit;
  final double minStock;
  final DateTime? createdAt;

  IngredientModel({
    this.id,
    this.adminId,
    required this.name,
    required this.category,
    this.stock = 0.0,
    this.unit = 'pcs',
    this.minStock = 1.0,
    this.createdAt,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      _$IngredientModelFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientModelToJson(this);
}
