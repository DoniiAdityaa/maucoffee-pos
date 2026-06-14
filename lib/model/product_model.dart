import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  final String? id;
  final String categoryId;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime? createdAt;

  ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.stock = 0,
    this.imageUrl,
    this.isAvailable = true,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
