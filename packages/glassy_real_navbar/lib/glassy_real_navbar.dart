/// A beautiful glassmorphism navigation bar for Flutter.
///
/// This library provides realistic glass effects with physics-based animations,
/// liquid lens effects, and extensive customization options.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:glassy_real_navbar/glassy_real_navbar.dart';
///
/// GlassNavBar(
///   selectedIndex: _index,
///   onItemSelected: (i) => setState(() => _index = i),
///   items: [
///     GlassNavBarItem(icon: Icons.home, title: 'Home'),
///     GlassNavBarItem(icon: Icons.search, title: 'Search'),
///     GlassNavBarItem(icon: Icons.person, title: 'Profile'),
///   ],
/// )
/// ```
///
/// ## Main Components
///
/// - [GlassNavBar] - The main navigation bar widget
/// - [GlassNavBarItem] - Individual navigation items
/// - [GlassContainer] - Standalone glass container for any content
/// - [GlassAnimation] - Physics-based animation presets
/// - [GlassNavBarPreset] - Pre-built theme configurations
library;

export 'src/glass_container.dart';
export 'src/glass_nav_bar.dart';
export 'src/glass_nav_item.dart';
export 'src/glass_animation.dart';
export 'src/glass_theme.dart';
