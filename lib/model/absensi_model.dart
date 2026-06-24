import 'package:json_annotation/json_annotation.dart';

part 'absensi_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AbsensiModel {
  final String? id;
  final String employeeId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? note;
  final DateTime? createdAt;

  @JsonKey(defaultValue: true)
  final bool isSynced;

  @JsonKey(includeFromJson: true, includeToJson: false)
  final Map<String, dynamic>? employees;

  String? get employeeName => employees?['name'] as String?;
  String? get employeeRole => employees?['role'] as String?;

  AbsensiModel({
    this.id,
    required this.employeeId,
    required this.clockIn,
    this.clockOut,
    this.note,
    this.createdAt,
    this.isSynced = true,
    this.employees,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) =>
      _$AbsensiModelFromJson(json);

  Map<String, dynamic> toJson() => _$AbsensiModelToJson(this);
}
