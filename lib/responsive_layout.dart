import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget? xSmall;
  final Widget? small;
  final Widget? medium;
  final Widget? large;
  final Widget? xLarge;
  final Widget? xxLarge;

  const ResponsiveLayout({
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isXXLarge(context)) {
          return xxLarge ??
              large ??
              medium ??
              small ??
              xSmall ??
              const SizedBox.shrink();
        } else if (isXLarge(context)) {
          return xLarge ??
              large ??
              medium ??
              small ??
              xSmall ??
              const SizedBox.shrink();
        } else if (isLarge(context)) {
          return large ?? medium ?? small ?? xSmall ?? const SizedBox.shrink();
        } else if (isMedium(context)) {
          return medium ?? small ?? xSmall ?? const SizedBox.shrink();
        } else if (isSmall(context)) {
          return small ?? xSmall ?? const SizedBox.shrink();
        } else {
          // X-Small
          return xSmall ?? const SizedBox.shrink();
        }
      },
    );
  }
}
