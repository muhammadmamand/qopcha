import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens the public shop profile / storefront for customers.
void openShopStorefront(
  BuildContext context, {
  required String shopOwnerId,
  String? shopName,
}) {
  final id = shopOwnerId.trim();
  if (id.isEmpty) return;
  final name = (shopName ?? '').trim();
  final path = name.isEmpty
      ? '/store/$id'
      : '/store/$id?name=${Uri.encodeQueryComponent(name)}';
  context.push(path);
}
