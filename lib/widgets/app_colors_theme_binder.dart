import 'package:flutter/material.dart';

import '../core/theme/app_color_theme.dart';
import '../core/theme/app_theme.dart';

/// Keeps [AppColors] in sync with [Theme] and force-rebuilds the subtree
/// when brightness or color pack flips — needed because many screens read
/// static AppColors and would otherwise stay stale.
class AppColorsThemeBinder extends StatelessWidget {
  final Widget child;
  final AppColorTheme colorTheme;

  const AppColorsThemeBinder({
    super.key,
    required this.child,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    AppColors.applyColorTheme(colorTheme);
    AppColors.applyBrightness(brightness);
    return _ThemeRebuildHost(
      brightness: brightness,
      colorTheme: colorTheme,
      child: child,
    );
  }
}

class _ThemeRebuildHost extends StatefulWidget {
  final Brightness brightness;
  final AppColorTheme colorTheme;
  final Widget child;

  const _ThemeRebuildHost({
    required this.brightness,
    required this.colorTheme,
    required this.child,
  });

  @override
  State<_ThemeRebuildHost> createState() => _ThemeRebuildHostState();
}

class _ThemeRebuildHostState extends State<_ThemeRebuildHost> {
  @override
  void didUpdateWidget(covariant _ThemeRebuildHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness ||
        oldWidget.colorTheme != widget.colorTheme) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _markDescendantsNeedsBuild(context as Element);
      });
    }
  }

  void _markDescendantsNeedsBuild(Element element) {
    element.visitChildren((child) {
      child.markNeedsBuild();
      _markDescendantsNeedsBuild(child);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
