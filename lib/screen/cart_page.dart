import 'package:agri_marketplace_app/address%20page.dart';
import 'package:agri_marketplace_app/models/product.dart';
import 'package:agri_marketplace_app/services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🛒 CartItem model
class CartItem {
  final String productId;
  String farmerId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    this.farmerId = "",
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

/// 🛒 CartPage
class CartPage extends StatefulWidget {
  final List<CartItem> initialCartItems;

  const CartPage({super.key, required this.initialCartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<CartItem> cartItems;

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.initialCartItems);
  }

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  /// ➕ Increase quantity
  void increaseQuantity(CartItem item) {
    setState(() => item.quantity++);
  }

  /// ➖ Decrease quantity
  void decreaseQuantity(CartItem item) {
    setState(() {
      if (item.quantity > 1) item.quantity--;
    });
  }

  /// ❌ Remove item
  void removeItem(CartItem item) {
    setState(() => cartItems.remove(item));
  }

  /// 🏷 Proceed to Address Page
  void proceedToAddress() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Your cart is empty!")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerAddressPage(
          orderItems: {for (var e in cartItems) e.productId: e.quantity},
          totalAmount: totalPrice,
          cartItems: cartItems
              .map(
                (e) => Product(
                  id: e.productId,
                  name: e.name,
                  price: e.price,
                  farmerId: e.farmerId,
                  quantity: e.quantity,
                  description: '',
                  imageUrl: '',
                  createdAt: Timestamp.now(),
                  category: '',
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// ✅ Direct Checkout via OrderService
  Future<void> checkout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Your cart is empty!")));
      return;
    }

    final buyerId = FirebaseAuth.instance.currentUser?.uid;
    if (buyerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    try {
      // Convert cart items to map
      final cartData = cartItems.map((item) {
        return {
          "productId": item.productId,
          "name": item.name,
          "quantity": item.quantity,
          "price": item.price,
        };
      }).toList();

      // Place order for each cart item (single product per order)
      for (final item in cartData) {
        await OrderService().placeOrder(
          buyerId: buyerId,
          productId: item["productId"] as String,
          productName: item["name"] as String,
          quantity: item["quantity"] as int,
          price: item["price"] as double,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Order placed successfully!")),
      );

      setState(() => cartItems.clear());

      // Navigate back to dashboard or home
      Navigator.pushReplacementNamed(context, '/buyer-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to place order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Your Cart"),
        backgroundColor: Colors.green[800],
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty!",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_basket),
                    title: Text(item.name),
                    subtitle: Text(
                      '₹${item.price.toStringAsFixed(2)} x ${item.quantity}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => decreaseQuantity(item),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => increaseQuantity(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  "₹${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Proceed Button
            ElevatedButton.icon(
              onPressed: proceedToAddress,
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              label: const Text(
                "Proceed to Address",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
