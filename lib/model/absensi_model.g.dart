// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absensi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbsensiModel _$AbsensiModelFromJson(Map<String, dynamic> json) => AbsensiModel(
  id: json['id'] as String?,
  employeeId: json['employee_id'] as String,
  clockIn: DateTime.parse(json['clock_in'] as String),
  clockOut: json['clock_out'] == null
      ? null
      : DateTime.parse(json['clock_out'] as String),
  note: json['note'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  isSynced: json['is_synced'] as bool? ?? true,
  employees: json['employees'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AbsensiModelToJson(AbsensiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'clock_in': instance.clockIn.toIso8601String(),
      'clock_out': instance.clockOut?.toIso8601String(),
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
      'is_synced': instance.isSynced,
    };
