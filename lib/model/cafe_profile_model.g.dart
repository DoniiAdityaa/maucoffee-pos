// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cafe_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CafeProfileModel _$CafeProfileModelFromJson(Map<String, dynamic> json) =>
    CafeProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CafeProfileModelToJson(CafeProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
