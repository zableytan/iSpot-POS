import '../models/order.dart';
import '../models/product.dart';
import 'inventory_service.dart';

class OrderService {
  final InventoryService _inventoryService;
  final Map<String, Order> _orders = {};

  OrderService(this._inventoryService);

  // Create a new order
  Future<Order> createOrder({
    required String id,
    required List<OrderItem> items,
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
    final order = Order.create(
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

    _orders[order.id] = order;
    return order;
  }

  // Get an order by ID
  Future<Order?> getOrder(String id) async {
    return _orders[id];
  }

  // Get all orders
  Future<List<Order>> getAllOrders() async {
    return _orders.values.toList();
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    return _orders.values
        .where((order) => order.status == status)
        .toList();
  }

  // Update order status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    final order = _orders[orderId];
    if (order == null) {
      throw Exception('Order not found');
    }

    order.status = status;
    return order;
  }

  // Cancel order and restore inventory
  Future<Order> cancelOrder(String orderId) async {
    final order = _orders[orderId];
    if (order == null) {
      throw Exception('Order not found');
    }

    if (order.status == OrderStatus.cancelled) {
      throw Exception('Order is already cancelled');
    }

    // Restore inventory
    for (var item in order.items) {
      await _inventoryService.increaseStock(item.product.id, item.quantity);
    }

    order.status = OrderStatus.cancelled;
    return order;
  }

  // Get daily sales report
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
    final dailyOrders = _orders.values.where((order) =>
        order.orderDate.year == date.year &&
        order.orderDate.month == date.month &&
        order.orderDate.day == date.day &&
        order.status == OrderStatus.completed);

    final totalSales = dailyOrders.fold(0.0, (sum, order) => sum + order.total);
    final totalOrders = dailyOrders.length;

    return {
      'date': date.toIso8601String(),
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'orders': dailyOrders.map((order) => order.toMap()).toList(),
    };
  }
}