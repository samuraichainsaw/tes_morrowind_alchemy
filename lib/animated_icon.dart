import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class CartTarget {
  final GlobalKey targetKey;
  final Widget targetWidget;

  CartTarget({required this.targetKey, required this.targetWidget});
}

class AnimatedIcon extends StatefulWidget {
  final Widget tapTarget;
  final List<CartTarget> cartTargets;
  final Duration animationDuration;
  final Widget icon;
  final int numberOfIcons;
  final Curve animationCurve;

  const AnimatedIcon({
    super.key,
    required this.tapTarget,
    required this.cartTargets,
    this.animationDuration = const Duration(milliseconds: 700),
    this.icon = const Icon(Icons.shopping_cart),
    this.numberOfIcons = 1,
    this.animationCurve = Curves.easeInOut,
  });

  @override
  _AnimatedCartIconState createState() => _AnimatedCartIconState();
}

class _AnimatedCartIconState extends State<AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Animation<double>> _animations = [];
  final List<GlobalKey> _iconKeys = [];
  final GlobalKey _tapTargetKey = GlobalKey();
  final List<ValueNotifier<double>> _opacityNotifiers = [];
  final List<ValueNotifier<Offset>> _positionNotifiers = [];

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: widget.animationDuration);

    for (int i = 0; i < widget.numberOfIcons; i++) {
      _iconKeys.add(GlobalKey());
      _opacityNotifiers.add(ValueNotifier<double>(1.0));
      _positionNotifiers.add(ValueNotifier<Offset>(Offset.zero));
      _animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _animationController, curve: widget.animationCurve),
        ),
      );
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset all animations and opacities
        for (var notifier in _opacityNotifiers) {
          notifier.value = 1.0;
        }
        for (var notifier in _positionNotifiers) {
          notifier.value = Offset.zero;
        }
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var notifier in _opacityNotifiers) {
      notifier.dispose();
    }
    for (var notifier in _positionNotifiers) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _startAnimation(Offset tapPosition) {
    if (widget.cartTargets.isEmpty) return;

    RenderBox tapTargetRenderBox =
        _tapTargetKey.currentContext?.findRenderObject() as RenderBox;
    Offset tapTargetPosition = tapTargetRenderBox.localToGlobal(Offset.zero);
    Size tapTargetSize = tapTargetRenderBox.size;

    // Distribute animations across targets.
    // Each target is responsible for a portion of the icons,
    // distributing them as evenly as possible.
    int targetIndex = 0;
    int iconsPerTarget = widget.numberOfIcons ~/ widget.cartTargets.length;
    int remainingIcons = widget.numberOfIcons % widget.cartTargets.length;
    int iconsAssigned = 0;

    for (int i = 0; i < widget.numberOfIcons; i++) {
      if (iconsAssigned >= iconsPerTarget + (remainingIcons > 0 ? 1 : 0)) {
        iconsAssigned = 0;
        targetIndex++;
        if (remainingIcons > 0) {
          remainingIcons--;
        }
      }

      final currentTarget = widget.cartTargets[targetIndex];

      RenderBox targetRenderBox = currentTarget.targetKey.currentContext
          ?.findRenderObject() as RenderBox;
      Offset targetPosition = targetRenderBox.localToGlobal(Offset.zero);
      Offset myPosition =
          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
      Size targetSize = targetRenderBox.size;

      double size = 25;
      if ((widget.icon as Icon).size != null) {
        size = (widget.icon as Icon).size!;
      }
      double startX = tapPosition.dx - size / 2 - myPosition.dx;
      double startY = tapPosition.dy - size / 2 - myPosition.dy;

      double endX =
          targetPosition.dx + targetSize.width / 2 - size / 2 - myPosition.dx;
      double endY =
          targetPosition.dy + targetSize.height / 2 - size / 2 - myPosition.dy;

      final index = i;
      _animations[index].addListener(() {
        final animationValue = _animations[index].value;

        // Calculate the current position along a curved path
        final vector.Vector2 start = vector.Vector2(startX, startY);
        final vector.Vector2 end = vector.Vector2(endX, endY);
        final vector.Vector2 controlPoint = vector.Vector2(
          startX + (endX - startX) / 2,
          startY - 100,
        ); // Adjust control point for curve

        final vector.Vector2 p = vector.Vector2(
          (1 - animationValue) * (1 - animationValue) * start.x +
              2 * (1 - animationValue) * animationValue * controlPoint.x +
              animationValue * animationValue * end.x,
          (1 - animationValue) * (1 - animationValue) * start.y +
              2 * (1 - animationValue) * animationValue * controlPoint.y +
              animationValue * animationValue * end.y,
        );

        _positionNotifiers[index].value = Offset(p.x, p.y);
        _opacityNotifiers[index].value = 1 - animationValue * 0.7;
      });

      iconsAssigned++;
    }

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTapDown: (details) {
            _startAnimation(details.globalPosition);
          },
          child: Container(
            key: _tapTargetKey,
            child: widget.tapTarget,
          ),
        ),
        ..._buildAnimatedIcons(),
      ],
    );
  }

  List<Widget> _buildAnimatedIcons() {
    List<Widget> icons = [];
    for (int i = 0; i < widget.numberOfIcons; i++) {
      icons.add(
        ValueListenableBuilder<Offset>(
          valueListenable: _positionNotifiers[i],
          builder: (context, position, child) {
            return ValueListenableBuilder<double>(
              valueListenable: _opacityNotifiers[i],
              builder: (context, opacity, child) {
                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: Opacity(
                    opacity: opacity,
                    child: IconTheme(
                      data: IconThemeData(
                          size: 24, color: (widget.icon as Icon).color),
                      child: widget.icon,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
    return icons;
  }
}
