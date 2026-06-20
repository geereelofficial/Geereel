import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data-layer shape of a `/api/users/:uid` response.
///
/// Kept separate from [UserEntity] so transport-specific concerns (JSON
/// serialization, date conversion) never leak into the domain layer.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String username,
    required String displayName,
    required String email,
    String? photoUrl,
    @Default('') String bio,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    @TimestampConverter() required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelMapper on UserModel {
  UserEntity toEntity() => UserEntity(
    uid: uid,
    username: username,
    displayName: displayName,
    email: email,
    photoUrl: photoUrl,
    bio: bio,
    followersCount: followersCount,
    followingCount: followingCount,
    postsCount: postsCount,
    createdAt: createdAt,
  );
}
