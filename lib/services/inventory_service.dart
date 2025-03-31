import '../models/product.dart';

class InventoryService {
  // In-memory storage for products (replace with database later)
  final Map<String, Product> _products = {};

  // Add a new product to inventory
  Future<Product> addProduct(Product product) async {
    _products[product.id] = product;
    return product;
  }

  // Get a product by ID
  Future<Product?> getProduct(String id) async {
    return _products[id];
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    return _products.values.toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    return _products.values
        .where((product) => product.category == category)
        .toList();
  }

  // Update product stock
  Future<Product> updateStock(String productId, int quantity) async {
    final product = _products[productId];
    if (product == null) {
      throw Exception('Product not found');
    }

    product.stockQuantity = quantity;
    product.updatedAt = DateTime.now();
    return product;
  }

  // Decrease stock (for sales)
  Future<Product> decreaseStock(String productId, int quantity) async {
    final product = _products[productId];
    if (product == null) {
      throw Exception('Product not found');
    }

    if (product.stockQuantity < quantity) {
      throw Exception('Insufficient stock');
    }

    product.stockQuantity -= quantity;
    product.updatedAt = DateTime.now();
    return product;
  }

  // Increase stock (for restocking)
  Future<Product> increaseStock(String productId, int quantity) async {
    final product = _products[productId];
    if (product == null) {
      throw Exception('Product not found');
    }

    product.stockQuantity += quantity;
    product.updatedAt = DateTime.now();
    return product;
  }

  // Get low stock products (below threshold)
  Future<List<Product>> getLowStockProducts(int threshold) async {
    return _products.values
        .where((product) => product.stockQuantity <= threshold)
        .toList();
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    _products.remove(productId);
  }
}