import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when the user re-taps the Home tab to scroll back to top.
final homeScrollToTopTriggerProvider = StateProvider<int>((ref) => 0);

void triggerHomeScrollToTop(WidgetRef ref) {
  ref.read(homeScrollToTopTriggerProvider.notifier).update((n) => n + 1);
}
