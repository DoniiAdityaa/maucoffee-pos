// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientModel _$IngredientModelFromJson(Map<String, dynamic> json) =>
    IngredientModel(
      id: json['id'] as String?,
      adminId: json['admin_id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 1.0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$IngredientModelToJson(IngredientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'name': instance.name,
      'category': instance.category,
      'stock': instance.stock,
      'unit': instance.unit,
      'min_stock': instance.minStock,
      'created_at': instance.createdAt?.toIso8601String(),
    };
