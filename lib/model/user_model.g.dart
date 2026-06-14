// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String?,
  name: json['name'] as String?,
  email: json['email'] as String?,
  photo: json['photo'] as String?,
  username: json['username'] as String?,
  bio: json['bio'] as String?,
  country: json['country'] as String?,
  topics: (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'photo': instance.photo,
  'username': instance.username,
  'bio': instance.bio,
  'country': instance.country,
  'topics': instance.topics,
};
