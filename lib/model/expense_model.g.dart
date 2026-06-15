// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) => ExpenseModel(
  id: json['id'] as String?,
  adminId: json['admin_id'] as String?,
  title: json['title'] as String,
  amount: (json['amount'] as num).toDouble(),
  category: json['category'] as String,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'title': instance.title,
      'amount': instance.amount,
      'category': instance.category,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };
