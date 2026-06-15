// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['id'] as String?,
  adminId: json['admin_id'] as String?,
  categoryId: json['category_id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  imageUrl: json['image_url'] as String?,
  isAvailable: json['is_available'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'category_id': instance.categoryId,
      'name': instance.name,
      'price': instance.price,
      'stock': instance.stock,
      'image_url': instance.imageUrl,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt?.toIso8601String(),
    };
