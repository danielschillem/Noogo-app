import 'package:flutter/material.dart';

/// Responsive breakpoints & helpers for Noogo.
///
/// Usage:
/// ```dart
/// if (Responsive.isTablet(context)) { ... }
///
/// Responsive.value(
///   context,
///   phone: 16.0,
///   tablet: 24.0,
/// )
/// ```
class Responsive {
  Responsive._();

  // ── Breakpoints ──────────────────────────────────────────────────────────

  /// Small phones: < 360 dp
  static const double _breakSmall = 360;

  /// Tablet threshold: ≥ 600 dp (Material 3 recommendation)
  static const double _breakTablet = 600;

  /// Desktop/large tablet threshold: ≥ 900 dp
  static const double _breakDesktop = 900;

  // ── Classification helpers ───────────────────────────────────────────────

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// True on small phones (< 360 dp).
  static bool isSmallPhone(BuildContext context) =>
      _width(context) < _breakSmall;

  /// True on phones (< 600 dp).
  static bool isPhone(BuildContext context) => _width(context) < _breakTablet;

  /// True on tablets (600 dp ≤ width < 900 dp).
  static bool isTablet(BuildContext context) {
    final w = _width(context);
    return w >= _breakTablet && w < _breakDesktop;
  }

  /// True on large tablets / desktops (≥ 900 dp).
  static bool isDesktop(BuildContext context) =>
      _width(context) >= _breakDesktop;

  /// True on tablets OR larger screens.
  static bool isTabletOrLarger(BuildContext context) =>
      _width(context) >= _breakTablet;

  // ── Value picker ─────────────────────────────────────────────────────────

  /// Returns [tablet] on tablets/desktops, [phone] otherwise.
  /// If [desktop] is provided, it is used for widths ≥ 900 dp.
  static T value<T>(
    BuildContext context, {
    required T phone,
    required T tablet,
    T? desktop,
  }) {
    final w = _width(context);
    if (w >= _breakDesktop && desktop != null) return desktop;
    if (w >= _breakTablet) return tablet;
    return phone;
  }

  // ── Grid helpers ─────────────────────────────────────────────────────────

  /// Number of columns for a grid (e.g. menu grid, dish grid).
  static int gridColumns(BuildContext context) => value(
        context,
        phone: 2,
        tablet: 3,
        desktop: 4,
      );

  /// Horizontal padding for page content.
  static double horizontalPadding(BuildContext context) => value(
        context,
        phone: 16.0,
        tablet: 32.0,
        desktop: 48.0,
      );

  /// Max content width (centered on large screens).
  static double maxWidth(BuildContext context) => value(
        context,
        phone: double.infinity,
        tablet: 720.0,
        desktop: 960.0,
      );

  /// Font scale multiplier relative to phone baseline.
  static double fontScale(BuildContext context) => value(
        context,
        phone: 1.0,
        tablet: 1.1,
        desktop: 1.15,
      );
}

/// Wraps [child] in a centered container limited to [Responsive.maxWidth].
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final maxW = Responsive.maxWidth(context);
    final hPad = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(padding: hPad, child: child),
      ),
    );
  }
}

/// Adaptive page layout: on tablets shows a two-column layout
/// with an optional persistent [sidebar] and the main [body].
class AdaptivePageLayout extends StatelessWidget {
  const AdaptivePageLayout({
    super.key,
    required this.body,
    this.sidebar,
    this.sidebarWidth = 280,
  });

  final Widget body;
  final Widget? sidebar;
  final double sidebarWidth;

  @override
  Widget build(BuildContext context) {
    if (sidebar == null || Responsive.isPhone(context)) {
      return body;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: sidebarWidth, child: sidebar!),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ],
    );
  }
}
