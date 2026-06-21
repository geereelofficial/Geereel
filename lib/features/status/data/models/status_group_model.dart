import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/status_entity.dart';
import 'status_model.dart';

part 'status_group_model.freezed.dart';
part 'status_group_model.g.dart';

/// Data-layer shape of one entry in the `/api/statuses` tray response.
@freezed
abstract class StatusGroupModel with _$StatusGroupModel {
  const factory StatusGroupModel({
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required List<StatusModel> statuses,
    @Default(false) bool hasUnviewed,
  }) = _StatusGroupModel;

  factory StatusGroupModel.fromJson(Map<String, dynamic> json) => _$StatusGroupModelFromJson(json);
}

extension StatusGroupModelMapper on StatusGroupModel {
  StatusGroupEntity toEntity() => StatusGroupEntity(
    authorId: authorId,
    authorUsername: authorUsername,
    authorPhotoUrl: authorPhotoUrl,
    statuses: statuses.map((s) => s.toEntity()).toList(),
    hasUnviewed: hasUnviewed,
  );
}
