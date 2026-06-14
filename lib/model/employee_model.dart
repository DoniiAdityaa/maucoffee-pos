import 'package:json_annotation/json_annotation.dart';

part 'employee_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EmployeeModel {
  final String? id;
  final String name;
  final String role; // 'Admin', 'Cashier', 'Barista'
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;

  EmployeeModel({
    this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.isActive = true,
    this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeModelFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeModelToJson(this);
}
