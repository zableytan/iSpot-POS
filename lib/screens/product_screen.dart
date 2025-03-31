import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';

class ProductScreen extends StatefulWidget {
  final InventoryService inventoryService;

  const ProductScreen({Key? key, required this.inventoryService}) : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  ProductCategory _selectedCategory = ProductCategory.beer;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await widget.inventoryService.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  Future<void> _showAddProductDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<ProductCategory>(
                value: _selectedCategory,
                items: ProductCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Initial Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final product = Product(
                id: DateTime.now().toString(), // Replace with proper ID generation
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                category: _selectedCategory,
                description: descriptionController.text,
                stockQuantity: int.tryParse(stockController.text) ?? 0,
              );

              await widget.inventoryService.addProduct(product);
              Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(
              '${product.category.toString().split('.').last} - \$${product.price.toStringAsFixed(2)}',
            ),
            trailing: Text('Stock: ${product.stockQuantity}'),
            onTap: () {
              // TODO: Implement edit product functionality
            },
          );
        },
      ),
    );
  }
}