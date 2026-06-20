import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'search_providers.g.dart';

/// Debounced username/display-name search, backing the search screen.
///
/// Named [UserSearchController] (not `SearchController`) to avoid colliding
/// with `package:flutter/material.dart`'s own `SearchController`.
@riverpod
class UserSearchController extends _$UserSearchController {
  Timer? _debounce;

  @override
  FutureOr<List<UserEntity>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return [];
  }

  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    state = const AsyncLoading();
    final result = await ref.read(searchUsersUseCaseProvider).call(query);
    state = switch (result) {
      Ok(value: final users) => AsyncData(users),
      Err(failure: final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
