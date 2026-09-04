import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when the user re-taps the Home tab to scroll back to top.
final homeScrollToTopTriggerProvider = StateProvider<int>((ref) => 0);

/// Liquid-glass nav paints above Flutter modal routes; hide it while a
/// root-level sheet/dialog needs the full screen.
final shellModalChromeHiddenProvider = StateProvider<bool>((ref) => false);

void triggerHomeScrollToTop(WidgetRef ref) {
  ref.read(homeScrollToTopTriggerProvider.notifier).update((n) => n + 1);
}

/// [showModalBottomSheet] on the root navigator + hide liquid-glass nav.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetRef ref,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) async {
  final chrome = ref.read(shellModalChromeHiddenProvider.notifier);
  chrome.state = true;
  try {
    return await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: builder,
    );
  } finally {
    chrome.state = false;
  }
}
