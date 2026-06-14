import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: "id")
  String? id;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "email")
  String? email;
  @JsonKey(name: "photo")
  String? photo;
  @JsonKey(name: "username")
  String? username;
  @JsonKey(name: "bio")
  String? bio;
  @JsonKey(name: "country")
  String? country;
  @JsonKey(name: "topics")
  List<String>? topics;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.photo,
    this.username,
    this.bio,
    this.country,
    this.topics,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
