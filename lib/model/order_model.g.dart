// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String?,
  invoiceNumber: json['invoice_number'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String,
  amountPaid: (json['amount_paid'] as num).toDouble(),
  change: (json['change'] as num?)?.toDouble() ?? 0,
  qrisProofUrl: json['qris_proof_url'] as String?,
  cashierId: json['cashier_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_number': instance.invoiceNumber,
      'total_amount': instance.totalAmount,
      'payment_method': instance.paymentMethod,
      'amount_paid': instance.amountPaid,
      'change': instance.change,
      'qris_proof_url': instance.qrisProofUrl,
      'cashier_id': instance.cashierId,
      'created_at': instance.createdAt?.toIso8601String(),
    };
