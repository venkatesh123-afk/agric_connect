import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test widget to verify order flow
class TestOrderFlow extends StatelessWidget {
  const TestOrderFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Order Flow"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Order Flow Test",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Test buttons
            ElevatedButton(
              onPressed: () => _testCreateOrder(context),
              child: const Text("Test Create Order"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _viewOrders(context),
              child: const Text("View All Orders"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _viewFarmerOrders(context),
              child: const Text("View Farmer Orders"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _viewBuyerOrders(context),
              child: const Text("View Buyer Orders"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateOrder(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }

      // Create a test order
      final ordersRef = FirebaseFirestore.instance.collection("orders");
      final orderId = ordersRef.doc().id;

      await ordersRef.doc(orderId).set({
        "orderId": orderId,
        "buyerId": user.uid,
        "farmerId": user.uid, // Same user for testing
        "productId": "test_product_123",
        "productName": "Test Tomato",
        "quantity": 2,
        "price": 50.0,
        "totalAmount": 100.0,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Test order created: $orderId")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  Future<void> _viewOrders(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("orders")
          .get();

      final orders = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return "${doc.id}: ${data['productName']} - ${data['status']}";
          })
          .join('\n');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("All Orders"),
          content: SingleChildScrollView(
            child: Text(orders.isEmpty ? "No orders found" : orders),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  Future<void> _viewFarmerOrders(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("orders")
          .where("farmerId", isEqualTo: user.uid)
          .get();

      final orders = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return "${doc.id}: ${data['productName']} - ${data['status']}";
          })
          .join('\n');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Farmer Orders"),
          content: SingleChildScrollView(
            child: Text(orders.isEmpty ? "No farmer orders found" : orders),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  Future<void> _viewBuyerOrders(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("orders")
          .where("buyerId", isEqualTo: user.uid)
          .get();

      final orders = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return "${doc.id}: ${data['productName']} - ${data['status']}";
          })
          .join('\n');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Buyer Orders"),
          content: SingleChildScrollView(
            child: Text(orders.isEmpty ? "No buyer orders found" : orders),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }
}
