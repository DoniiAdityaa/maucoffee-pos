import 'package:json_annotation/json_annotation.dart';

part 'stock_log_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StockLogModel {
  final String? id;
  final String? adminId;
  final String ingredientName;
  final String category;
  final double adjustedAmount;
  final double stockBefore;
  final double stockAfter;
  final String type; // 'Tambah', 'Kurang', 'Baru'
  final DateTime? createdAt;

  StockLogModel({
    this.id,
    this.adminId,
    required this.ingredientName,
    required this.category,
    required this.adjustedAmount,
    required this.stockBefore,
    required this.stockAfter,
    required this.type,
    this.createdAt,
  });

  factory StockLogModel.fromJson(Map<String, dynamic> json) =>
      _$StockLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockLogModelToJson(this);
}
