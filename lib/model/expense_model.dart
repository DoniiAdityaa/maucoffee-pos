import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ExpenseModel {
  final String? id;
  final String? adminId;
  final String title;
  final double amount;
  final String category; // 'Operational', 'Ingredients', 'Salary', 'Rent', etc.
  final String? notes;
  final DateTime? createdAt;

  ExpenseModel({
    this.id,
    this.adminId,
    required this.title,
    required this.amount,
    required this.category,
    this.notes,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
}
