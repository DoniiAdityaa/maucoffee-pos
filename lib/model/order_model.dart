import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderModel {
  final String? id;
  final String invoiceNumber;
  final double totalAmount;
  final String paymentMethod; // 'Cash', 'QRIS', 'Card'
  final double amountPaid;
  final double change;
  final String? qrisProofUrl;
  final String? cashierId;
  final DateTime? createdAt;

  OrderModel({
    this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    this.change = 0,
    this.qrisProofUrl,
    this.cashierId,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
