import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/status_viewer_entity.dart';

part 'status_viewer_model.freezed.dart';
part 'status_viewer_model.g.dart';

/// Data-layer shape of one `/api/statuses/:statusId/viewers` entry.
@freezed
abstract class StatusViewerModel with _$StatusViewerModel {
  const factory StatusViewerModel({
    required String uid,
    required String username,
    String? photoUrl,
    @TimestampConverter() required DateTime viewedAt,
  }) = _StatusViewerModel;

  factory StatusViewerModel.fromJson(Map<String, dynamic> json) => _$StatusViewerModelFromJson(json);
}

extension StatusViewerModelMapper on StatusViewerModel {
  StatusViewerEntity toEntity() =>
      StatusViewerEntity(uid: uid, username: username, photoUrl: photoUrl, viewedAt: viewedAt);
}
