import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_providers.g.dart';

/// Registered on the root [GoRouter]'s `observers`. [HomeShell] subscribes
/// to this with [RouteAware] (using the shell's own root-level page route)
/// to detect when a top-level screen — profile, post detail, chat, search,
/// etc., all declared as siblings of the shell rather than nested inside it
/// — is pushed on top of the bottom-nav shell, so the feed can pause its
/// video instead of playing audio behind it. [PostDetailScreen] subscribes
/// the same way using its own route, for the case where a *further* screen
/// is pushed on top of it specifically.
///
/// This is deliberately Flutter's built-in [RouteObserver] mechanism rather
/// than a hand-rolled push/pop counter: a counter that increments on every
/// `didPush` and decrements on every `didPop`/`didRemove` looks right but
/// breaks on `redirect`/`go()` transitions (e.g. the initial /login → /feed
/// redirect), where a route can be removed with no matching `previousRoute`
/// to pair the decrement against — leaving the counter permanently stuck
/// above zero and every video silently refusing to autoplay until tapped.
/// [RouteAware.didPushNext]/[didPopNext] don't have that failure mode since
/// each subscriber tracks its own coverage directly.
final routeObserver = RouteObserver<PageRoute<dynamic>>();

/// Whether the bottom-nav shell (and therefore the feed) is currently
/// covered by a top-level screen pushed on top of it. Driven by
/// [HomeShell]'s [RouteAware] callbacks.
@riverpod
class IsShellCovered extends _$IsShellCovered {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}
