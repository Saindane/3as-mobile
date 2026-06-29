import 'package:flutter/material.dart';
import 'responsive.dart';

/// Renders a grid that adjusts column count by breakpoint
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns  = 2,
    this.tabletColumns  = 3,
    this.desktopColumns = 4,
    this.spacing        = 12,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final cols = adaptive<int>(context,
      mobile:  mobileColumns,
      tablet:  tabletColumns,
      desktop: desktopColumns,
    );
    return GridView.count(
      crossAxisCount:   cols,
      crossAxisSpacing: spacing,
      mainAxisSpacing:  spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap:       true,
      physics:          const NeverScrollableScrollPhysics(),
      children:         children,
    );
  }
}

/// Two-column on desktop, single column on mobile
class ResponsiveTwoCol extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;

  const ResponsiveTwoCol({
    super.key,
    required this.left,
    required this.right,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          SizedBox(width: spacing),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [left, SizedBox(height: spacing), right],
    );
  }
}
