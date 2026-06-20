import 'dart:io';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class UploadAvatar {
  final AuthRepository _repository;

  const UploadAvatar(this._repository);

  Future<Result<String>> call({required String uid, required File file}) {
    return _repository.uploadAvatar(uid: uid, file: file);
  }
}
