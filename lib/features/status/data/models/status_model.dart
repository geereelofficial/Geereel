import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/status_entity.dart';

part 'status_model.freezed.dart';
part 'status_model.g.dart';

/// Data-layer shape of one status item, as returned both nested inside a
/// tray group and flat from `/api/statuses/user/:authorId`.
@freezed
abstract class StatusModel with _$StatusModel {
  const factory StatusModel({
    required String statusId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required MediaType mediaType,
    required String mediaUrl,
    String? thumbnailUrl,
    double? durationSeconds,
    int? width,
    int? height,
    @Default(0) int viewsCount,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime expiresAt,
    @Default(false) bool viewed,
  }) = _StatusModel;

  factory StatusModel.fromJson(Map<String, dynamic> json) => _$StatusModelFromJson(json);
}

extension StatusModelMapper on StatusModel {
  StatusEntity toEntity() => StatusEntity(
    statusId: statusId,
    authorId: authorId,
    authorUsername: authorUsername,
    authorPhotoUrl: authorPhotoUrl,
    mediaType: mediaType,
    mediaUrl: mediaUrl,
    thumbnailUrl: thumbnailUrl,
    durationSeconds: durationSeconds,
    width: width,
    height: height,
    viewsCount: viewsCount,
    createdAt: createdAt,
    expiresAt: expiresAt,
    viewed: viewed,
  );
}
