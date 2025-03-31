import 'package:flutter/foundation.dart';
import 'product.dart';

enum OrderStatus {
  pending,
  completed,
  cancelled
}

class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    String? notes,
  }) : 
    this.totalPrice = quantity * unitPrice,
    this.notes = notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': product.id,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      product: Product.fromMap({'id': map['productId']} as Map<String, dynamic>, id: map['productId']),
      quantity: map['quantity'] as int,
      unitPrice: map['unitPrice'] as double,
      notes: map['notes'] as String?,
    );
  }
}

class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime orderDate;
  OrderStatus status;
  final double subtotal;
  final double tax;
  final double total;
  final String? customerName;
  final String? tableNumber;
  final String? notes;

  Order({
    required this.id,
    required this.items,
    required this.orderDate,
    this.status = OrderStatus.pending,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.customerName,
    this.tableNumber,
    this.notes,
  });

  factory Order.create({
    required String id,
    required List<OrderItem> items,
    String? customerName,
    String? tableNumber,
    String? notes,
  }) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final tax = subtotal * 0.1; // 10% tax rate
    final total = subtotal + tax;

    return Order(
      id: id,
      items: items,
      orderDate: DateTime.now(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      customerName: customerName,
      tableNumber: tableNumber,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'customerName': customerName,
      'tableNumber': tableNumber,
      'notes': notes,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {required String id}) {
    return Order(
      id: id,
      items: (map['items'] as List<dynamic>).map((item) => OrderItem.fromMap(item as Map<String, dynamic>)).toList(),
      orderDate: DateTime.parse(map['orderDate'] as String),
      status: OrderStatus.values.firstWhere((e) => e.toString() == map['status']),
      subtotal: map['subtotal'] as double,
      tax: map['tax'] as double,
      total: map['total'] as double,
      customerName: map['customerName'] as String?,
      tableNumber: map['tableNumber'] as String?,
      notes: map['notes'] as String?,
    );
  }
}