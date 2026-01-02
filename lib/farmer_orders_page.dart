import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class FarmerOrdersPage extends StatelessWidget {
  const FarmerOrdersPage({super.key});

  // --- Get Buyer Display Name ---
  Future<String> _getBuyerDisplayName(String buyerId) async {
    try {
      final buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(buyerId)
          .get();
      if (buyerDoc.exists) {
        final name = buyerDoc.data()?['name'];
        if (name != null && name.toString().trim().isNotEmpty) return name;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(buyerId)
          .get();
      if (userDoc.exists) {
        final name = userDoc.data()?['name'];
        if (name != null && name.toString().trim().isNotEmpty) return name;
      }
    } catch (e) {
      debugPrint("Error getting buyer name: $e");
    }

    final abbrev = buyerId.substring(0, math.min(8, buyerId.length));
    return "$abbrev...";
  }

  // --- Get Product Image ---
  Future<String> _getProductImage(
    String productId,
    String productImageUrl,
  ) async {
    if (productImageUrl.isNotEmpty) return productImageUrl;
    if (productId.isEmpty) return '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return data['imageUrl'] ?? '';
      }
    } catch (e) {
      debugPrint("Error getting product image: $e");
    }

    return '';
  }

  // --- Get Feedback for Order ---
  Future<Map<String, dynamic>?> _getFeedbackForOrder(String orderId) async {
    try {
      final farmerId = FirebaseAuth.instance.currentUser?.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          // CHANGED: original code used 'orderId' but you told me the field name is 'orderid'
          .where('orderid', isEqualTo: orderId)
          .where('farmerId', isEqualTo: farmerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      debugPrint("Error getting feedback: $e");
      return null;
    }
  }

  // --- Update Order Status ---
  Future<void> _updateProductStatus(
    String orderDocId,
    String newStatus,
    BuildContext context,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderDocId);

      final updates = <String, dynamic>{'status': newStatus};
      final now = FieldValue.serverTimestamp();

      switch (newStatus.toLowerCase()) {
        case 'accepted':
          updates['acceptedAt'] = now;
          break;
        case 'shipped':
          updates['shippedAt'] = now;
          updates['deliveredAt'] = FieldValue.delete();
          updates['isReceived'] = false;
          break;
        case 'delivered':
          updates['deliveredAt'] = now;
          updates['isReceived'] = false;
          break;
      }

      await docRef.update(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Order marked as $newStatus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Confirmation Dialog (generic) ---
  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    Color confirmColor = Colors.green,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // NOTE: _showNotAllowedDialog has been removed from flow per your instruction
  // (we keep the function here only if you want to reuse it later; currently it's unused)

  // --- Delete Order & Related Feedbacks ---
  Future<void> _deleteOrderAndFeedbacks(
    BuildContext context, {
    required String orderId,
    required String productId,
  }) async {
    try {
      // Delete the order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();

      // Query feedbacks by orderId and productId and delete them
      final feedbacks = await FirebaseFirestore.instance
          .collection('feedbacks')
          // CHANGED: use 'orderid' as you specified
          .where('orderid', isEqualTo: orderId)
          .where('productId', isEqualTo: productId)
          .get();

      for (var doc in feedbacks.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Order and feedback deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Product Image Widget ---
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(),
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  // --- Status Color ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade200;
      case 'accepted':
        return Colors.blue.shade200;
      case 'shipped':
        return Colors.purple.shade200;
      case 'delivered':
        return Colors.green.shade200;
      case 'declined':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  // --- Action Buttons ---
  List<Widget> _buildProductActionButtons(
    BuildContext context,
    String orderDocId,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return [
          ElevatedButton(
            onPressed: () =>
                _showConfirmDialog(
                  context,
                  title: 'Accept Order',
                  message: 'Accept this order?',
                  confirmText: 'Accept',
                  confirmColor: Colors.green,
                ).then((confirmed) {
                  if (confirmed == true) {
                    _updateProductStatus(orderDocId, 'accepted', context);
                  }
                }),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () =>
                _showConfirmDialog(
                  context,
                  title: 'Decline Order',
                  message: 'Decline this order?',
                  confirmText: 'Decline',
                  confirmColor: Colors.red,
                ).then((confirmed) {
                  if (confirmed == true) {
                    _updateProductStatus(orderDocId, 'declined', context);
                  }
                }),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ];

      case 'accepted':
        return [
          ElevatedButton(
            onPressed: () =>
                _showConfirmDialog(
                  context,
                  title: 'Mark as Shipped',
                  message: 'Confirm shipped?',
                  confirmText: 'Shipped',
                  confirmColor: Colors.blue,
                ).then((confirmed) {
                  if (confirmed == true) {
                    _updateProductStatus(orderDocId, 'shipped', context);
                  }
                }),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Shipped', style: TextStyle(color: Colors.white)),
          ),
        ];

      case 'shipped':
        return [
          ElevatedButton(
            onPressed: () =>
                _showConfirmDialog(
                  context,
                  title: 'Mark as Delivered',
                  message: 'Confirm delivered?',
                  confirmText: 'Delivered',
                  confirmColor: Colors.purple,
                ).then((confirmed) {
                  if (confirmed == true) {
                    _updateProductStatus(orderDocId, 'delivered', context);
                  }
                }),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text(
              'Delivered',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ];

      case 'delivered':
        return [const Text("✅ Delivered")];
      case 'declined':
        return [const Text("❌ Declined")];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerId = FirebaseAuth.instance.currentUser?.uid;
    if (farmerId == null) {
      return const Scaffold(body: Center(child: Text("⚠ Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Farmer Orders"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('farmerId', isEqualTo: farmerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders yet."));
          }

          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final orderId = doc.id;

              final productId = data['productId'] ?? '';
              final productImageUrl = data['productImageUrl'] ?? '';
              final productName = data['productName'] ?? 'Unknown';
              final buyerId = data['buyerId'] ?? '';
              final quantity = (data['quantity'] ?? 0).toDouble();
              final price = (data['price'] ?? 0).toDouble();
              final total = price * quantity;
              final status = (data['status'] ?? 'pending').toString();
              final createdAt = data['createdAt'] as Timestamp?;
              final isReceived = data['isReceived'] == true;

              return FutureBuilder<String>(
                future: _getProductImage(productId, productImageUrl),
                builder: (context, imgSnap) {
                  final imageUrl = imgSnap.data ?? '';

                  // CHANGED: per your final instruction, make top delete always enabled.
                  // final canDelete previously checked status; now it's always true.

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            leading: _buildProductImage(imageUrl),
                            title: Text(productName),
                            subtitle: createdAt != null
                                ? Text(
                                    "Ordered: ${DateFormat.yMMMd().add_jm().format(createdAt.toDate())}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Text("Status: "),
                                    Chip(
                                      label: Text(status.toUpperCase()),
                                      backgroundColor: _getStatusColor(status),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: _buildProductActionButtons(
                                  context,
                                  orderId,
                                  status,
                                ),
                              ),
                              const Divider(),
                              FutureBuilder<String>(
                                future: _getBuyerDisplayName(buyerId),
                                builder: (context, buyerSnap) {
                                  final buyerName = buyerSnap.data ?? '...';
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("👤 Buyer: $buyerName"),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "💰 Total: ₹${total.toStringAsFixed(2)} (x$quantity)",
                                ),
                              ),
                              // --- FEEDBACK SECTION ---
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _getFeedbackForOrder(orderId),
                                builder: (context, feedbackSnap) {
                                  if (feedbackSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Loading feedback..."),
                                    );
                                  }

                                  final feedback = feedbackSnap.data;
                                  if (feedback == null) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("No feedback yet."),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "⭐ Rating: ${feedback['rating']} / 5",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "💬 Feedback: ${feedback['feedback']}",
                                        ),
                                        const SizedBox(height: 10),
                                        // Keep the old delete UI for delivered+received items as well
                                        if (status.toLowerCase() ==
                                                'delivered' &&
                                            isReceived)
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            label: const Text(
                                              "Delete Item",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    "Delete Delivered Item",
                                                  ),
                                                  content: const Text(
                                                    "Are you sure you want to delete this delivered item and its feedback?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        "Cancel",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        "Delete",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await _deleteOrderAndFeedbacks(
                                                  context,
                                                  orderId: orderId,
                                                  productId: productId,
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Positioned delete button (top-right floating)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Material(
                            // small elevation to appear above card
                            elevation: 2,
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextButton.icon(
                              onPressed: () async {
                                // CHANGED: always enabled — simply ask confirm then delete.
                                final confirmed = await _showConfirmDialog(
                                  context,
                                  title:
                                      'Confirm Delete', // CHANGED: per your final choice
                                  message:
                                      'Do you want to delete this order permanently?',
                                  confirmText: 'Delete',
                                  confirmColor: Colors.red,
                                );
                                if (confirmed == true) {
                                  await _deleteOrderAndFeedbacks(
                                    context,
                                    orderId: orderId,
                                    productId: productId,
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
