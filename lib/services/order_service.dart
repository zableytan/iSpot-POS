import '../models/order.dart' as models;
import '../models/order.dart' show OrderStatus;
import '../models/product.dart';
import 'inventory_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final InventoryService _inventoryService;
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  OrderService(this._inventoryService);

  // Create a new order
  Future<models.Order> createOrder({
    required String id,
    required List<models.OrderItem> items,
    String? customerName,
    String? tableNumber,
    String? notes,
  }) async {
    // Check stock availability for all items
    for (var item in items) {
      final product = await _inventoryService.getProduct(item.product.id);
      if (product == null || product.stockQuantity < item.quantity) {
        throw Exception('Insufficient stock for ${item.product.name}');
      }
    }

    // Create the order
    final order = models.Order.create(
      id: id,
      items: items,
      customerName: customerName,
      tableNumber: tableNumber,
      notes: notes,
    );

    // Update inventory
    for (var item in items) {
      await _inventoryService.decreaseStock(item.product.id, item.quantity);
    }

    await _ordersCollection.doc(order.id).set(order.toMap());
    return order;
  }

  // Get an order by ID
  Future<models.Order?> getOrder(String id) async {
    final doc = await _ordersCollection.doc(id).get();
    if (!doc.exists) return null;
    return models.Order.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  // Get all orders
  Future<List<models.Order>> getAllOrders() async {
    final snapshot = await _ordersCollection.get();
    return snapshot.docs
        .map((doc) => models.Order.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  // Get orders by status
  Future<List<models.Order>> getOrdersByStatus(models.OrderStatus status) async {
    final snapshot = await _ordersCollection
        .where('status', isEqualTo: status.toString())
        .get();
    return snapshot.docs
        .map((doc) => models.Order.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
  }

  // Update order status
  Future<models.Order> updateOrderStatus(String orderId, models.OrderStatus status) async {
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) {
      throw Exception('Order not found');
    }

    await _ordersCollection.doc(orderId).update({'status': status.toString()});
    final updatedDoc = await _ordersCollection.doc(orderId).get();
    return models.Order.fromMap(updatedDoc.data() as Map<String, dynamic>, id: updatedDoc.id);
  }

  // Cancel order and restore inventory
  Future<models.Order> cancelOrder(String orderId) async {
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) {
      throw Exception('Order not found');
    }

    final order = models.Order.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    if (order.status == models.OrderStatus.cancelled) {
      throw Exception('Order is already cancelled');
    }

    // Restore inventory
    for (var item in order.items) {
      await _inventoryService.increaseStock(item.product.id, item.quantity);
    }

    await _ordersCollection.doc(orderId).update({'status': models.OrderStatus.cancelled.toString()});
    final updatedDoc = await _ordersCollection.doc(orderId).get();
    return models.Order.fromMap(updatedDoc.data() as Map<String, dynamic>, id: updatedDoc.id);
  }

  // Get daily sales report
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _ordersCollection
        .where('orderDate', isGreaterThanOrEqualTo: startOfDay)
        .where('orderDate', isLessThan: endOfDay)
        .where('status', isEqualTo: models.OrderStatus.completed.toString())
        .get();

    final orders = snapshot.docs
        .map((doc) => models.Order.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();

    final totalSales = orders.fold(0.0, (sum, order) => sum + order.total);
    final totalOrders = orders.length;

    return {
      'date': date.toIso8601String(),
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'orders': orders.map((order) => order.toMap()).toList(),
    };
  }
}