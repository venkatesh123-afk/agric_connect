import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Places an order for a product.
  /// Automatically fetches the farmerId from the product document.
  Future<void> placeOrder({
    required String buyerId,
    required String productId,
    required String productName,
    required int quantity,
    required double price,
  }) async {
    try {
      final ordersCollection = _firestore.collection('orders');

      // Fetch the product document to get the farmerId
      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw Exception("Product not found");
      }

      final farmerId = productDoc['farmerId'];
      if (farmerId == null || farmerId.isEmpty) {
        throw Exception("Farmer ID not found for this product");
      }

      // Generate a unique order ID
      final String orderId = ordersCollection.doc().id;

      // Save the order in Firestore
      await ordersCollection.doc(orderId).set({
        "orderId": orderId,
        "buyerId": buyerId,
        "productId": productId,
        "farmerId": farmerId,
        "productName": productName,
        "quantity": quantity,
        "price": price,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Optional: log the error or rethrow
      print("Error placing order: $e");
      rethrow;
    }
  }
}
