import 'package:flutter/material.dart';

/// Breakpoints matching our web demo design
class Breakpoints {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;
}

/// Returns true when running on a wide screen (tablet/desktop/web)
bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.mobile &&
    MediaQuery.of(context).size.width < Breakpoints.tablet;

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < Breakpoints.mobile;

/// Adaptive value — pick the right value for current screen size
T adaptive<T>(BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  final w = MediaQuery.of(context).size.width;
  if (w >= Breakpoints.tablet) return desktop;
  if (w >= Breakpoints.mobile) return tablet ?? desktop;
  return mobile;
}

/// ResponsiveLayout — shows different widgets per breakpoint
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= Breakpoints.tablet) return desktop;
    if (w >= Breakpoints.mobile) return tablet ?? desktop;
    return mobile;
  }
}
