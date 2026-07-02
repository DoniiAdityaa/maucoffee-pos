import 'package:json_annotation/json_annotation.dart';

part 'cafe_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CafeProfileModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final DateTime? updatedAt;

  CafeProfileModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.updatedAt,
  });

  factory CafeProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CafeProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$CafeProfileModelToJson(this);
}
