import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_viewer_entity.freezed.dart';

/// One entry in a status's "viewed by" list, shown to the status's author.
@freezed
abstract class StatusViewerEntity with _$StatusViewerEntity {
  const factory StatusViewerEntity({
    required String uid,
    required String username,
    String? photoUrl,
    required DateTime viewedAt,
  }) = _StatusViewerEntity;
}
