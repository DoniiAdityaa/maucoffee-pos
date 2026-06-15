import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CategoryModel {
  final String? id;
  final String? adminId;
  final String name;
  final DateTime? createdAt;

  CategoryModel({this.id, this.adminId, required this.name, this.createdAt});

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}
