import 'package:flutter/material.dart';

/// Represents a single navigation item in [GlassNavBar].
///
/// Each item displays an icon and optional title. You can provide a different
/// icon for the selected state using [activeIcon].
///
/// Example:
/// ```dart
/// GlassNavBarItem(
///   icon: Icons.home_outlined,
///   activeIcon: Icons.home,
///   title: 'Home',
///   semanticLabel: 'Navigate to home screen',
/// )
/// ```
class GlassNavBarItem {
  /// The icon to display when this item is not selected.
  ///
  /// Consider using outlined variants here and filled variants for [activeIcon].
  final IconData icon;

  /// The text label for this item.
  ///
  /// Shown below the icon when [GlassNavBar.showLabels] is true.
  final String title;

  /// The icon to display when this item is selected.
  ///
  /// If null, [icon] is used for both states.
  /// Consider using filled variants here for visual distinction.
  final IconData? activeIcon;

  /// Semantic label for accessibility.
  ///
  /// This text is read by screen readers to describe the navigation destination.
  /// If null, [title] is used as the semantic label.
  ///
  /// Example: "Navigate to home screen" or "Open search"
  final String? semanticLabel;

  /// Optional badge count to display on this item.
  ///
  /// When non-null and greater than 0, a badge is displayed on the icon.
  /// Set to -1 to show a badge dot without a number.
  final int? badge;

  /// Color of the badge.
  ///
  /// Defaults to red if not specified.
  final Color? badgeColor;

  /// Creates a navigation bar item.
  ///
  /// The [icon] and [title] parameters are required.
  const GlassNavBarItem({
    required this.icon,
    required this.title,
    this.activeIcon,
    this.semanticLabel,
    this.badge,
    this.badgeColor,
  });

  /// Creates a copy of this item with the given fields replaced.
  GlassNavBarItem copyWith({
    IconData? icon,
    String? title,
    IconData? activeIcon,
    String? semanticLabel,
    int? badge,
    Color? badgeColor,
  }) {
    return GlassNavBarItem(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      activeIcon: activeIcon ?? this.activeIcon,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      badge: badge ?? this.badge,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlassNavBarItem &&
        other.icon == icon &&
        other.title == title &&
        other.activeIcon == activeIcon &&
        other.semanticLabel == semanticLabel &&
        other.badge == badge &&
        other.badgeColor == badgeColor;
  }

  @override
  int get hashCode {
    return Object.hash(
        icon, title, activeIcon, semanticLabel, badge, badgeColor);
  }
}
