import 'package:flutter/material.dart';

import 'mock_product_data.dart';
import 'pd_theme.dart';

class AccordionDetails extends StatefulWidget {
  final List<MockAccordionItem> items;

  const AccordionDetails({super.key, required this.items});

  @override
  State<AccordionDetails> createState() => _AccordionDetailsState();
}

class _AccordionDetailsState extends State<AccordionDetails> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وردەکاری',
          style: PdTheme.label(size: 17, weight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: PdColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PdColors.border.withValues(alpha: 0.95)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final open = _openIndex == i;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  Material(
                    color: open
                        ? PdColors.primary.withValues(alpha: 0.08)
                        : PdColors.card,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _openIndex = open ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: PdTheme.label(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: open ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 260),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: open
                                        ? PdColors.primary
                                        : PdColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox(
                                width: double.infinity,
                              ),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  item.body,
                                  style: PdTheme.body(size: 13.5, height: 1.55),
                                ),
                              ),
                              crossFadeState: open
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 240),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: PdColors.border.withValues(alpha: 0.9),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
