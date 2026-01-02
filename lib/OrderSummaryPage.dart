import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CustomerPaymentPage.dart';
import '../models/product.dart';

class OrderSummaryPage extends StatefulWidget {
  final Map<Product, int> orderItems;
  final Map<String, dynamic> address;
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;
  final int currentStep;

  const OrderSummaryPage({
    super.key,
    required this.orderItems,
    required this.address,
    required this.totalAmount,
    required this.cartItems,
    this.currentStep = 1,
  });

  static const List<String> checkoutSteps = [
    'Address',
    'Order Summary',
    'Payment',
  ];

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  late Map<String, dynamic> currentAddress;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    currentAddress = Map<String, dynamic>.from(widget.address);
  }

  // ---------- Checkout Step Header ----------
  Widget _buildCheckoutHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(OrderSummaryPage.checkoutSteps.length, (index) {
          bool active = index <= widget.currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  OrderSummaryPage.checkoutSteps[index],
                  style: TextStyle(
                    color: active ? Colors.green : Colors.grey[600],
                    fontWeight: index == widget.currentStep
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------- Place Order ----------
  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final ordersRef = FirebaseFirestore.instance.collection("orders");
      final orderId = ordersRef.doc().id;

      final farmerIds = widget.orderItems.keys.map((p) => p.farmerId).toSet();

      await ordersRef.doc(orderId).set({
        "orderId": orderId,
        "buyerId": user.uid,
        "farmerIds": farmerIds.toList(),
        "totalItems": widget.orderItems.length,
        "totalAmount": widget.totalAmount,
        "address": currentAddress,
        "status": "pending",
        // Explicitly mark as parent so queries with isNull work
        "parentOrderId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      final itemsRef = ordersRef.doc(orderId).collection("items");
      for (final entry in widget.orderItems.entries) {
        final product = entry.key;
        final quantity = entry.value;

        // 1) Save under items subcollection (for quick item listing)
        final itemDoc = itemsRef.doc();
        await itemDoc.set({
          "itemId": itemDoc.id,
          "productId": product.id,
          "farmerId": product.farmerId,
          "productName": product.name,
          "price": product.price,
          "quantity": quantity,
          "totalPrice": product.price * quantity,
          "productImageUrl": product.imageUrl,
        });

        // Ensure we have an image URL; fall back to products collection if empty
        String childImageUrl = product.imageUrl;
        if (childImageUrl.isEmpty) {
          try {
            final pDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(product.id)
                .get();
            if (pDoc.exists) {
              final pdata = pDoc.data();
              childImageUrl = (pdata?['imageUrl'] ?? '').toString();
            }
          } catch (_) {}
        }

        // 2) Create a per-product child order in top-level 'orders' (for farmer views)
        final childOrderId = ordersRef.doc().id;
        await ordersRef.doc(childOrderId).set({
          "orderId": childOrderId,
          "parentOrderId": orderId,
          "buyerId": user.uid,
          "farmerId": product.farmerId,
          "productId": product.id,
          "productName": product.name,
          "productImageUrl": childImageUrl,
          "price": product.price,
          "quantity": quantity,
          "totalPrice": product.price * quantity,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerPaymentPage(
            orderId: orderId,
            totalAmount: widget.totalAmount,
            address: currentAddress,
            orderItems: widget.orderItems,
            cartItems: [],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error placing order: $e")));
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  // ---------- Edit Address ----------
  Future<void> _editAddressDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentAddress["name"]);
    final phoneCtrl = TextEditingController(text: currentAddress["phone"]);
    final streetCtrl = TextEditingController(text: currentAddress["street"]);
    final cityCtrl = TextEditingController(text: currentAddress["city"]);
    final stateCtrl = TextEditingController(text: currentAddress["state"]);
    final pincodeCtrl = TextEditingController(text: currentAddress["pincode"]);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Address"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextFormField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(labelText: "Street"),
                ),
                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: "City"),
                ),
                TextFormField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: "State"),
                ),
                TextFormField(
                  controller: pincodeCtrl,
                  decoration: const InputDecoration(labelText: "Pincode"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentAddress = {
                  "name": nameCtrl.text,
                  "phone": phoneCtrl.text,
                  "street": streetCtrl.text,
                  "city": cityCtrl.text,
                  "state": stateCtrl.text,
                  "pincode": pincodeCtrl.text,
                };
              });
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------- Build UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Order Summary",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckoutHeader(),

          // ---------- Address Card ----------
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(currentAddress["name"] ?? "No Name"),
              subtitle: Text(
                "${currentAddress["street"]}, ${currentAddress["city"]}, ${currentAddress["state"]} - ${currentAddress["pincode"]}\nPhone: ${currentAddress["phone"] ?? ''}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: _editAddressDialog,
              ),
            ),
          ),

          // ---------- Order Items (Names, Prices, Quantities only) ----------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.orderItems.length,
              itemBuilder: (context, index) {
                final product = widget.orderItems.keys.elementAt(index);
                final quantity = widget.orderItems[product]!;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("₹${product.price} × $quantity"),
                    trailing: Text(
                      "₹${(product.price * quantity).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ---------- Total & Proceed Button ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "₹${widget.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Proceed to Payment",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
