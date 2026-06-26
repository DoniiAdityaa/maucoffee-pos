// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockLogModel _$StockLogModelFromJson(Map<String, dynamic> json) =>
    StockLogModel(
      id: json['id'] as String?,
      adminId: json['admin_id'] as String?,
      ingredientName: json['ingredient_name'] as String,
      category: json['category'] as String,
      adjustedAmount: (json['adjusted_amount'] as num).toDouble(),
      stockBefore: (json['stock_before'] as num).toDouble(),
      stockAfter: (json['stock_after'] as num).toDouble(),
      type: json['type'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$StockLogModelToJson(StockLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'ingredient_name': instance.ingredientName,
      'category': instance.category,
      'adjusted_amount': instance.adjustedAmount,
      'stock_before': instance.stockBefore,
      'stock_after': instance.stockAfter,
      'type': instance.type,
      'created_at': instance.createdAt?.toIso8601String(),
    };
