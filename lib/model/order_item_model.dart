import 'package:json_annotation/json_annotation.dart';

part 'order_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItemModel {
  final String? id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price; // Harga saat dibeli
  final String? notes; // Catatan (contoh: "Less Ice")
  final DateTime? createdAt;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.notes,
    this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}
