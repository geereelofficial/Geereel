import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Domain representation of a Geereel user profile.
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String uid,
    required String username,
    required String displayName,
    required String email,
    String? photoUrl,
    @Default('') String bio,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    required DateTime createdAt,
  }) = _UserEntity;
}
