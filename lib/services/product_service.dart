import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  Future<List<ProductModel>> getAllProducts() async {
    final snap = await _products.get();
    final list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<ProductModel>> getProductsByShop(String shopOwnerId) async {
    final snap =
        await _products.where('shopOwnerId', isEqualTo: shopOwnerId).get();
    final list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final snap = await _products.where('isFeatured', isEqualTo: true).get();
    final list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getAllProducts();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return products;
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.shopName.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (category == 'هەموو') return getAllProducts();
    final snap = await _products.where('category', isEqualTo: category).get();
    final list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    final now = DateTime.now();
    final ref = _products.doc();
    final newProduct = product.copyWith(
      id: ref.id,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(newProduct.toJson());
    return newProduct;
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _products
        .doc(product.id)
        .set(updated.toJson(), SetOptions(merge: true));
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  ProductModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return ProductModel.fromJson(data);
  }
}
