import 'package:flutter/material.dart';

import 'effects/indicator_effect.dart';
import 'effects/worm_effect.dart';
import 'painters/indicator_painter.dart';

typedef OnDotClicked = void Function(int index);

class SmoothPageIndicator extends AnimatedWidget {
  // Page view controller
  final PageController controller;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  final IndicatorEffect effect;

  /// layout direction vertical || horizontal
  ///
  /// This will only rotate the canvas in which the dots
  /// are drawn,
  /// It will not affect [effect.dotWidth] and [effect.dotHeight]
  final Axis axisDirection;

  /// The number of pages
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page direction will be flipped
  final TextDirection? textDirection;

  /// on dot clicked callback
  final OnDotClicked? onDotClicked;

  const SmoothPageIndicator({
    Key? key,
    required this.controller,
    required this.count,
    this.axisDirection = Axis.horizontal,
    this.textDirection,
    this.onDotClicked,
    this.effect = const WormEffect(),
  }) : super(key: key, listenable: controller);

  @override
  Widget build(BuildContext context) {
    return SmoothIndicator(
      offset: _offset,
      count: count,
      effect: effect,
      textDirection: textDirection,
      axisDirection: axisDirection,
      onDotClicked: onDotClicked,
    );
  }

  double get _offset {
    try {
      var offset = controller.page ?? controller.initialPage.toDouble();
      return offset % count;
    } catch (_) {
      return controller.initialPage.toDouble();
    }
  }
}

class SmoothIndicator extends StatelessWidget {
  // to listen for page offset updates
  final double offset;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  final IndicatorEffect effect;

  /// layout direction vertical || horizontal
  final Axis axisDirection;

  /// The number of pages
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page direction will be flipped
  final TextDirection? textDirection;

  /// on dot clicked callback
  final OnDotClicked? onDotClicked;

  SmoothIndicator({
    Key? key,
    required this.offset,
    required this.count,
    this.axisDirection = Axis.horizontal,
    this.effect = const WormEffect(),
    this.textDirection,
    this.onDotClicked,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) {
    // if textDirection is not provided use the nearest directionality up the widgets tree;
    final isRTL =
        (textDirection ?? Directionality.of(context)) == TextDirection.rtl;

    return RotatedBox(
      quarterTurns: axisDirection == Axis.vertical
          ? 1
          : isRTL
              ? 2
              : 0,
      child: GestureDetector(
        onTapUp: _onTap,
        child: CustomPaint(
          size: effect.calculateSize(count),
          // rebuild the painter with the new offset every time it updates
          painter: effect.buildPainter(count, offset),
        ),
      ),
    );
  }

  void _onTap(details) {
    if (onDotClicked != null) {
      var index = effect.hitTestDots(
        details.localPosition.dx,
        count,
        offset,
      );
      if (index >= 0) {
        onDotClicked?.call(index);  
      }
    }
  }
}

class AnimatedSmoothIndicator extends ImplicitlyAnimatedWidget {
  final int activeIndex;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  final IndicatorEffect effect;

  /// layout direction vertical || horizontal
  final Axis axisDirection;

  /// The number of children in [PageView]
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page direction will be flipped
  final TextDirection? textDirection;

  /// On dot clicked callback
  final Function(int index)? onDotClicked;

  const AnimatedSmoothIndicator({
    Key? key,
    required this.activeIndex,
    required this.count,
    this.axisDirection = Axis.horizontal,
    this.textDirection,
    this.onDotClicked,
    this.effect = const WormEffect(),
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onEnd,
  }) : super(
          key: key,
          duration: duration,
          curve: curve,
          onEnd: onEnd,
        );

  @override
  AnimatedSmoothIndicatorState createState() => AnimatedSmoothIndicatorState();
}

class AnimatedSmoothIndicatorState
    extends AnimatedWidgetBaseState<AnimatedSmoothIndicator> {
  Tween<double>? _offset;

  @override
  void forEachTween(visitor) {
    _offset = visitor(
      _offset,
      widget.activeIndex.toDouble(),
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>;
  }

  @override
  Widget build(BuildContext context) {
    final offset = _offset;
    if (offset == null) {
      throw 'Offset has not been initialized';
    }

    return SmoothIndicator(
      offset: offset.evaluate(animation),
      count: widget.count,
      effect: widget.effect,
      textDirection: widget.textDirection,
      axisDirection: widget.axisDirection,
      onDotClicked: widget.onDotClicked,
    );
  }
}
