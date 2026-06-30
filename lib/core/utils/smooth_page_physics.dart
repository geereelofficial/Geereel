import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Custom PageView scroll physics that mimics Instagram/Facebook Reels:
/// - Any flick velocity triggers a page snap (no need for a long swipe)
/// - A fast spring simulation settles the page quickly and cleanly
/// - Slightly underdamped spring gives a tiny, satisfying elastic snap
class SmoothPagePhysics extends ScrollPhysics {
  const SmoothPagePhysics({super.parent});

  @override
  SmoothPagePhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothPagePhysics(parent: buildParent(ancestor));
  }

  // Start responding to drag input almost immediately.
  @override
  double get dragStartDistanceMotionThreshold => 2.0;

  double _getPage(ScrollMetrics position) =>
      position.pixels / position.viewportDimension;

  double _getPixels(ScrollMetrics position, double page) =>
      page * position.viewportDimension;

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    // Any velocity above tolerance snaps to the next/previous page.
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return _getPixels(position, page.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return null;
    }
    final tolerance = this.tolerance;
    final target = _getTargetPixels(position, tolerance, velocity);
    if (target == position.pixels) return null;

    // Slightly underdamped spring (ratio 0.85) → quick snap with a tiny
    // satisfying bounce, exactly like Instagram Reels.
    return SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 0.4,
        stiffness: 120.0,
        ratio: 0.85,
      ),
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
