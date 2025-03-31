import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/inventory_service.dart';

class OrderScreen extends StatefulWidget {
  final OrderService orderService;
  final InventoryService inventoryService;

  const OrderScreen({
    Key? key,
    required this.orderService,
    required this.inventoryService,
  }) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final List<OrderItem> _items = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _tax => _subtotal * 0.1; // 10% tax rate
  double get _total => _subtotal + _tax;

  Future<void> _addProduct() async {
    final products = await widget.inventoryService.getAllProducts();
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available')),
      );
      return;
    }

    final Product? selectedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(
                  '${product.category.toString().split('.').last} - \$${product.price.toStringAsFixed(2)}',
                ),
                trailing: Text('Stock: ${product.stockQuantity}'),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
      ),
    );

    if (selectedProduct == null) return;

    final int? quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
          onSubmitted: (value) =>
              Navigator.pop(context, int.tryParse(value) ?? 1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, 1), // Default quantity is 1
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (quantity == null || quantity <= 0) return;

    setState(() {
      _items.add(OrderItem(
        id: DateTime.now().toString(),
        product: selectedProduct,
        quantity: quantity,
        unitPrice: selectedProduct.price,
      ));
    });
  }

  Future<void> _createOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the order')),
      );
      return;
    }

    try {
      final order = await widget.orderService.createOrder(
        id: DateTime.now().toString(),
        items: _items,
        customerName: _customerNameController.text,
        tableNumber: _tableNumberController.text,
        notes: _notesController.text,
      );

      setState(() {
        _items.clear();
        _customerNameController.clear();
        _tableNumberController.clear();
        _notesController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order.id} created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                  ),
                ),
                TextField(
                  controller: _tableNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Table Number',
                  ),
                ),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(
                    '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                  onLongPress: () {
                    setState(() {
                      _items.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('\$${_subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax (10%):'),
                    Text('\$${_tax.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:'),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addProduct,
            heroTag: 'add_product',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _createOrder,
            heroTag: 'create_order',
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}