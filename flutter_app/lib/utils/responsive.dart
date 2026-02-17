import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive utility class
class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  /// Get screen width
  double get width => MediaQuery.of(context).size.width;
  
  /// Get screen height
  double get height => MediaQuery.of(context).size.height;
  
  /// Check if mobile
  bool get isMobile => width < Breakpoints.mobile;
  
  /// Check if tablet
  bool get isTablet => width >= Breakpoints.mobile && width < Breakpoints.tablet;
  
  /// Check if desktop
  bool get isDesktop => width >= Breakpoints.desktop;
  
  /// Get responsive value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) {
      return desktop;
    } else if (isTablet && tablet != null) {
      return tablet;
    }
    return mobile;
  }
  
  /// Get responsive padding
  EdgeInsets getPadding({
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return value<EdgeInsets>(
      mobile: mobile ?? const EdgeInsets.all(16.0),
      tablet: tablet ?? const EdgeInsets.all(24.0),
      desktop: desktop ?? const EdgeInsets.all(32.0),
    );
  }
  
  /// Get responsive font size
  double getFontSize({
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    return value<double>(
      mobile: mobile ?? 14.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 18.0,
    );
  }
  
  /// Get responsive columns count
  int getColumns({
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return value<int>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Responsive widget wrapper
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    
    if (responsive.isDesktop && desktop != null) {
      return desktop!;
    } else if (responsive.isTablet && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final AlignmentGeometry? alignment;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.alignment,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    
    return Container(
      padding: padding ?? responsive.getPadding(),
      margin: margin,
      alignment: alignment,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: responsive.value<double>(
              mobile: double.infinity,
              tablet: responsive.isTablet ? maxWidth! * 0.9 : double.infinity,
              desktop: maxWidth!,
            ))
          : null,
      child: child,
    );
  }
}

/// Responsive grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final columns = responsive.getColumns(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );
    
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (responsive.width - (responsive.getPadding().horizontal) - (spacing * (columns - 1))) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}





