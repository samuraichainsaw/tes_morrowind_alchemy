import 'package:flutter/material.dart';

enum ResponsiveLayoutBreakPoints {
  xSmall,
  small,
  medium,
  large,
  xLarge,
  xxLarge,
}

class ResponsiveLayoutFn extends StatelessWidget {
  final Widget Function(ResponsiveLayoutBreakPoints className)? xSmall;

  final Widget Function(ResponsiveLayoutBreakPoints className)? small;

  final Widget Function(ResponsiveLayoutBreakPoints className)? medium;

  final Widget Function(ResponsiveLayoutBreakPoints className)? large;

  final Widget Function(ResponsiveLayoutBreakPoints className)? xLarge;

  final Widget Function(ResponsiveLayoutBreakPoints className)? xxLarge;

  const ResponsiveLayoutFn({
    super.key,
    this.xSmall,
    this.small,
    this.medium,
    this.large,
    this.xLarge,
    this.xxLarge,
  });

  static bool isXSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 576;

  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width >= 576 &&
      MediaQuery.of(context).size.width < 768;

  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 992;

  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 992 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isXLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200 &&
      MediaQuery.of(context).size.width < 1400;

  static bool isXXLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1400;

  Widget Function(ResponsiveLayoutBreakPoints className) getFn(context) {
    Widget empty(ResponsiveLayoutBreakPoints className) => SizedBox.shrink();

    if (isXXLarge(context)) {
      return (xxLarge ?? xLarge ?? large ?? medium ?? small ?? xSmall ?? empty);
    } else if (isXLarge(context)) {
      return (xLarge ?? large ?? medium ?? small ?? xSmall ?? empty);
    } else if (isLarge(context)) {
      return (large ?? medium ?? small ?? xSmall ?? empty);
    } else if (isMedium(context)) {
      return (medium ?? small ?? xSmall ?? empty);
    } else if (isSmall(context)) {
      return (small ?? xSmall ?? empty);
    } else {
      // X-Small
      return (xSmall ?? empty);
    }
  }

  static ResponsiveLayoutBreakPoints getBreakPoint(BuildContext context) {
    if (isXXLarge(context)) {
      return (ResponsiveLayoutBreakPoints.xxLarge);
    } else if (isXLarge(context)) {
      return (ResponsiveLayoutBreakPoints.xLarge);
    } else if (isLarge(context)) {
      return (ResponsiveLayoutBreakPoints.large);
    } else if (isMedium(context)) {
      return (ResponsiveLayoutBreakPoints.medium);
    } else if (isSmall(context)) {
      return (ResponsiveLayoutBreakPoints.small);
    } else {
      return (ResponsiveLayoutBreakPoints.xSmall);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return getFn(context)(getBreakPoint(context));
      },
    );
  }
}
