import 'package:flutter/material.dart';

import 'pd_theme.dart';

class DescriptionSection extends StatefulWidget {
  final String description;
  final String fabricBadge;

  const DescriptionSection({
    super.key,
    required this.description,
    required this.fabricBadge,
  });

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وەسف',
          style: PdTheme.label(size: 17, weight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Text(
            widget.description,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: PdTheme.body(size: 14.5, height: 1.6),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'کەمتر پیشان بدە' : 'زیاتر بخوێنەوە',
            style: PdTheme.label(
              size: 13,
              weight: FontWeight.w800,
              color: PdColors.primary,
            ),
          ),
        ),
        if (widget.fabricBadge.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            widget.fabricBadge,
            style: PdTheme.label(
              size: 13,
              weight: FontWeight.w700,
              color: PdColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
