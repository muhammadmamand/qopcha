import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme.dart';

/// Animated search field used on the home screen.
class HomeSearchField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const HomeSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  ConsumerState<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends ConsumerState<HomeSearchField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _caret;
  late final TextEditingController _textController;
  late final FocusNode _focus;

  Timer? _tick;
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _deleting = false;
  String _visible = '';
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller;
    _focus = widget.focusNode;
    _caret = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    _textController.addListener(_refresh);
    _focus.addListener(_refresh);
    _scheduleTick(const Duration(milliseconds: 80));
  }

  @override
  void dispose() {
    _alive = false;
    _tick?.cancel();
    _tick = null;
    _textController.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _caret.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!_alive || !mounted) return;
    setState(() {});
    if (_showHint && _tick == null) {
      _scheduleTick(const Duration(milliseconds: 120));
    }
  }

  bool get _showHint => _textController.text.isEmpty;

  void _scheduleTick(Duration delay) {
    _tick?.cancel();
    if (!_alive) return;
    _tick = Timer(delay, _onTick);
  }

  void _onTick() {
    _tick = null;
    if (!_alive || !mounted) return;

    if (!_showHint) {
      _scheduleTick(const Duration(milliseconds: 250));
      return;
    }

    final s = ref.read(stringsProvider);
    final hints = <String>[
      s.searchHintClothes,
      s.searchHintItems,
      s.searchHintShop,
    ];
    final full = hints[_hintIndex % hints.length];

    if (!_deleting) {
      if (_charIndex <= full.length) {
        _visible = full.substring(0, _charIndex);
        _charIndex++;
        setState(() {});
        _scheduleTick(const Duration(milliseconds: 48));
      } else {
        _deleting = true;
        _scheduleTick(const Duration(milliseconds: 1400));
      }
      return;
    }

    if (_charIndex > 0) {
      _charIndex--;
      _visible = full.substring(0, _charIndex);
      setState(() {});
      _scheduleTick(const Duration(milliseconds: 28));
      return;
    }

    _deleting = false;
    _hintIndex = (_hintIndex + 1) % 3;
    _scheduleTick(const Duration(milliseconds: 220));
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.brand;
    final hasText = _textController.text.isNotEmpty;
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 56,
      padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused
              ? accent.withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: focused ? accent : AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: accent,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (_showHint)
                  IgnorePointer(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _visible,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppColors.textTertiary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _caret,
                          child: Container(
                            width: 1.4,
                            height: 14,
                            margin: const EdgeInsetsDirectional.only(start: 2),
                            color: accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (hasText)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClear,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onFilterTap,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
