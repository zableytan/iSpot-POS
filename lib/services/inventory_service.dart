import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // Add a new product to inventory
  Future<Product> addProduct(Product product) async {
    await _productsCollection.doc(product.id).set(product.toMap());
    return product;
  }

  // Get a product by ID
  Future<Product?> getProduct(String id) async {
    final doc = await _productsCollection.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final snapshot = await _productsCollection.get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    final snapshot = await _productsCollection
        .where('category', isEqualTo: category.toString())
        .get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  // Update product stock
  Future<Product> updateStock(String productId, int quantity) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) {
      throw Exception('Product not found');
    }

    final updatedData = {
      'stockQuantity': quantity,
      'updatedAt': DateTime.now(),
    };

    await _productsCollection.doc(productId).update(updatedData);
    final updatedDoc = await _productsCollection.doc(productId).get();
    return Product.fromMap(updatedDoc.data() as Map<String, dynamic>, id: updatedDoc.id);
  }

  // Decrease stock (for sales)
  Future<Product> decreaseStock(String productId, int quantity) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) {
      throw Exception('Product not found');
    }

    final product = Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    if (product.stockQuantity < quantity) {
      throw Exception('Insufficient stock');
    }

    final updatedData = {
      'stockQuantity': product.stockQuantity - quantity,
      'updatedAt': DateTime.now(),
    };

    await _productsCollection.doc(productId).update(updatedData);
    final updatedDoc = await _productsCollection.doc(productId).get();
    return Product.fromMap(updatedDoc.data() as Map<String, dynamic>, id: updatedDoc.id);
  }

  // Increase stock (for restocking)
  Future<Product> increaseStock(String productId, int quantity) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) {
      throw Exception('Product not found');
    }

    final product = Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    final updatedData = {
      'stockQuantity': product.stockQuantity + quantity,
      'updatedAt': DateTime.now(),
    };

    await _productsCollection.doc(productId).update(updatedData);
    final updatedDoc = await _productsCollection.doc(productId).get();
    return Product.fromMap(updatedDoc.data() as Map<String, dynamic>, id: updatedDoc.id);
  }

  // Get low stock products (below threshold)
  Future<List<Product>> getLowStockProducts(int threshold) async {
    final snapshot = await _productsCollection
        .where('stockQuantity', isLessThanOrEqualTo: threshold)
        .get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }
}