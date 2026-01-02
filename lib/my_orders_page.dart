import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  // ---------- Status Tracker ----------
  Widget _buildHorizontalTracker({
    required DateTime? placedAt,
    required DateTime? acceptedAt,
    required DateTime? shippedAt,
    required DateTime? deliveredAt,
    required String currentStatus,
  }) {
    final statusLower = currentStatus.toLowerCase();
    final steps = [
      {"label": "Placed", "time": placedAt, "done": true},
      {
        "label": "Accepted",
        "time": acceptedAt,
        "done":
            statusLower == 'accepted' ||
            statusLower == 'shipped' ||
            statusLower == 'delivered',
      },
      {
        "label": "Shipped",
        "time": shippedAt,
        "done": statusLower == 'shipped' || statusLower == 'delivered',
      },
      {
        "label": "Delivered",
        "time": deliveredAt,
        "done": statusLower == 'delivered',
      },
    ];

    return SizedBox(
      height: 70,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            final isDone = step["done"] as bool;
            return Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: Text(
                    step["label"].toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                      color: isDone ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                if (step["time"] != null)
                  Text(
                    DateFormat.jm().format((step["time"] as DateTime)),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
              ],
            );
          } else {
            final prevStep = steps[(index - 1) ~/ 2];
            final nextStep = steps[(index + 1) ~/ 2];
            final isLineDone =
                (prevStep["done"] as bool) && (nextStep["done"] as bool);
            return Expanded(
              child: Container(
                height: 3,
                color: isLineDone ? Colors.green : Colors.grey[300],
              ),
            );
          }
        }),
      ),
    );
  }

  // ---------- Order Summary Card ----------
  Widget _buildOrderSummaryCard({
    required int totalItems,
    required double totalAmount,
    required String status,
    required int deliveredCount,
    required int declinedCount,
    required int receivedCount,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Items: $totalItems",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total Amount: ₹${totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusChip("Delivered: $deliveredCount", Colors.green),
                _buildStatusChip("Declined: $declinedCount", Colors.redAccent),
                _buildStatusChip("Received: $receivedCount", Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ---------- Mark as Received ----------
  Future<void> _markAsReceived(
    String orderId,
    String productDocId,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(productDocId)
          .update({'isReceived': true});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as received")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to mark as received: $e")));
    }
  }

  // ---------- Submit Feedback ----------
  Future<void> _submitFeedback(
    BuildContext context,
    String productId,
    String orderId,
    String feedback,
    int rating,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      final productData = productDoc.data();
      final farmerId = productData?['farmerId'];

      if (farmerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing farmer ID for this product")),
        );
        return;
      }

      final feedbackData = {
        'buyerId': user.uid,
        'buyerName': user.displayName ?? "Anonymous",
        'farmerId': farmerId,
        'orderId': orderId,
        'productId': productId,
        'feedback': feedback,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('feedbacks')
          .add(feedbackData);

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('feedbacks')
          .add(feedbackData);

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .collection('feedbacks')
          .add(feedbackData);

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'feedbackGiven': true},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Feedback submitted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to submit feedback: $e")),
      );
    }
  }

  // ---------- Delete a single item (productDoc) + its feedbacks ----------
  // CHANGED: new helper to delete only the item doc and its feedbacks, and remove parent order if empty.
  Future<void> _deleteSingleItemAndFeedbacks({
    required BuildContext context,
    required String parentOrderId, // the parent order (order summary) id
    required String
    itemDocId, // the child/item document id in 'orders' collection
    required String productId, // product id stored inside that item doc
  }) async {
    try {
      // 1) Delete the product item doc
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(itemDocId)
          .delete();

      // 2) Delete related feedback documents (robust: try multiple query fields)
      final Set<String> feedbackDocIds = {};

      // Query 1: where 'orderid' == itemDocId (you used 'orderid' elsewhere)
      final q1 = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderid', isEqualTo: itemDocId)
          .get()
          // ignore: invalid_return_type_for_catch_error
          .catchError((_) => QuerySnapshotFake.empty());
      for (var d in q1.docs) feedbackDocIds.add(d.id);

      // Query 2: where 'orderId' == itemDocId (in case of mixed capitalization)
      final q2 = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderId', isEqualTo: itemDocId)
          .get()
          // ignore: invalid_return_type_for_catch_error
          .catchError((_) => QuerySnapshotFake.empty());
      for (var d in q2.docs) feedbackDocIds.add(d.id);

      // Query 3: where 'orderid' == parentOrderId AND productId == productId
      // (covers the case feedback referenced parent order)
      final q3 = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderid', isEqualTo: parentOrderId)
          .where('productId', isEqualTo: productId)
          .get()
          // ignore: invalid_return_type_for_catch_error
          .catchError((_) => QuerySnapshotFake.empty());
      for (var d in q3.docs) feedbackDocIds.add(d.id);

      // Query 4: where 'orderId' == parentOrderId AND productId == productId
      final q4 = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderId', isEqualTo: parentOrderId)
          .where('productId', isEqualTo: productId)
          .get()
          // ignore: invalid_return_type_for_catch_error
          .catchError((_) => QuerySnapshotFake.empty());
      for (var d in q4.docs) feedbackDocIds.add(d.id);

      // Delete feedback docs collected
      for (var fid in feedbackDocIds) {
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .doc(fid)
            .delete();
      }

      // 3) If parent order has no more items, delete the parent order document
      final remainingItemsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('parentOrderId', isEqualTo: parentOrderId)
          .get();

      if (remainingItemsSnapshot.docs.isEmpty) {
        // Delete parent order doc
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(parentOrderId)
            .delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Item and related feedback(s) deleted"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete item: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerId = FirebaseAuth.instance.currentUser?.uid;
    if (buyerId == null) {
      return const Scaffold(body: Center(child: Text("⚠ Please login first")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 My Orders"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where("buyerId", isEqualTo: buyerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final order = orderDoc.data() as Map<String, dynamic>;
              final orderId = orderDoc.id;
              final totalAmount = (order["totalAmount"] ?? 0).toDouble();
              final status = order["status"]?.toString() ?? "Pending";

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where("parentOrderId", isEqualTo: orderId)
                    .snapshots(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData ||
                      productSnapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final products = productSnapshot.data!.docs;
                  final totalItems = products.length;

                  int deliveredCount = 0;
                  int declinedCount = 0;
                  int receivedCount = 0;
                  for (var p in products) {
                    final data = p.data() as Map<String, dynamic>;
                    final s = (data['status'] ?? '').toString().toLowerCase();
                    final received = data['isReceived'] ?? false;
                    if (s == 'delivered') deliveredCount++;
                    if (s == 'declined') declinedCount++;
                    if (received == true) receivedCount++;
                  }

                  // ✅ Auto-update parent order if all items are received
                  if (deliveredCount > 0 && deliveredCount == receivedCount) {
                    FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'status': 'delivered'});
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummaryCard(
                        totalItems: totalItems,
                        totalAmount: totalAmount,
                        status: status,
                        deliveredCount: deliveredCount,
                        declinedCount: declinedCount,
                        receivedCount: receivedCount,
                      ),
                      ...products.map((productDoc) {
                        final product =
                            productDoc.data() as Map<String, dynamic>;
                        final productId = product["productId"];
                        final quantity = (product["quantity"] ?? 0) as int;
                        final price = (product["price"] ?? 0).toDouble();
                        final productTotal = price * quantity;
                        final productStatus = (product['status'] ?? 'Pending')
                            .toString();
                        final isReceived = (product['isReceived'] ?? false);
                        final createdAtItem =
                            product['createdAt'] as Timestamp?;
                        final acceptedAt = product['acceptedAt'] as Timestamp?;
                        final shippedAt = product['shippedAt'] as Timestamp?;
                        final deliveredAt =
                            product['deliveredAt'] as Timestamp?;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection("products")
                              .doc(productId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox();
                            }
                            final productData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final productName =
                                productData["name"] ?? "Unnamed Product";
                            final productImageUrl =
                                productData["imageUrl"] ?? "";

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: productImageUrl.isNotEmpty
                                              ? Image.network(
                                                  productImageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Qty: $quantity × ₹${price.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "₹${productTotal.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildHorizontalTracker(
                                      placedAt: createdAtItem?.toDate(),
                                      acceptedAt: acceptedAt?.toDate(),
                                      shippedAt: shippedAt?.toDate(),
                                      deliveredAt: deliveredAt?.toDate(),
                                      currentStatus: productStatus,
                                    ),

                                    // CHANGED: Always-visible delete button (inside item) BEFORE mark-as-received and feedback buttons
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextButton.icon(
                                        icon: const Text(
                                          '🗑',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        label: const Text(
                                          'Delete Item',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text("Delete Item"),
                                              content: const Text(
                                                "Are you sure you want to delete this item and its feedback?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            // perform item deletion + feedback deletion + maybe parent deletion
                                            await _deleteSingleItemAndFeedbacks(
                                              context: context,
                                              parentOrderId: orderId,
                                              itemDocId: productDoc.id,
                                              productId: productId,
                                            );
                                          }
                                        },
                                      ),
                                    ),

                                    if (productStatus.toLowerCase() ==
                                            'delivered' &&
                                        !isReceived)
                                      TextButton(
                                        onPressed: () => _markAsReceived(
                                          orderDoc.id,
                                          productDoc.id,
                                          context,
                                        ),
                                        child: const Text("Mark as Received"),
                                      ),
                                    if (isReceived &&
                                        productStatus.toLowerCase() ==
                                            'delivered')
                                      TextButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              final feedbackController =
                                                  TextEditingController();
                                              int rating = 5;
                                              return StatefulBuilder(
                                                builder: (context, setState) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      "Feedback",
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              feedbackController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    "Write feedback",
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Row(
                                                          children: List.generate(5, (
                                                            index,
                                                          ) {
                                                            return IconButton(
                                                              icon: Icon(
                                                                index < rating
                                                                    ? Icons.star
                                                                    : Icons
                                                                          .star_border,
                                                                color: Colors
                                                                    .orange,
                                                              ),
                                                              onPressed: () =>
                                                                  setState(
                                                                    () => rating =
                                                                        index +
                                                                        1,
                                                                  ),
                                                            );
                                                          }),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          _submitFeedback(
                                                            context,
                                                            productId,
                                                            productDoc.id,
                                                            feedbackController
                                                                .text,
                                                            rating,
                                                          );
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                        child: const Text(
                                                          "Submit",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                        child: const Text("Give Feedback"),
                                      ),
                                    if (productStatus.toLowerCase() ==
                                            'delivered' &&
                                        isReceived)
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          "Delete Item",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Delete Item"),
                                              content: const Text(
                                                "Are you sure you want to delete this delivered item?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              // NOTE: previous behavior deleted parent order; we keep it to maintain prior behavior
                                              // but now we delete only this item doc:
                                              await FirebaseFirestore.instance
                                                  .collection('orders')
                                                  .doc(productDoc.id)
                                                  .delete();

                                              // Also delete feedbacks linked to this item (best-effort)
                                              // delete by orderid/item id and by productId+parentOrderId
                                              try {
                                                final Set<String> fids = {};

                                                final q1 = await FirebaseFirestore
                                                    .instance
                                                    .collection('feedbacks')
                                                    .where(
                                                      'orderid',
                                                      isEqualTo: productDoc.id,
                                                    )
                                                    .get()
                                                    .catchError(
                                                      (_) =>
                                                          // ignore: invalid_return_type_for_catch_error
                                                          QuerySnapshotFake.empty(),
                                                    );
                                                for (var d in q1.docs)
                                                  fids.add(d.id);

                                                final q2 = await FirebaseFirestore
                                                    .instance
                                                    .collection('feedbacks')
                                                    .where(
                                                      'orderId',
                                                      isEqualTo: productDoc.id,
                                                    )
                                                    .get()
                                                    .catchError(
                                                      (_) =>
                                                          // ignore: invalid_return_type_for_catch_error
                                                          QuerySnapshotFake.empty(),
                                                    );
                                                for (var d in q2.docs)
                                                  fids.add(d.id);

                                                final q3 = await FirebaseFirestore
                                                    .instance
                                                    .collection('feedbacks')
                                                    .where(
                                                      'orderid',
                                                      isEqualTo: orderId,
                                                    )
                                                    .where(
                                                      'productId',
                                                      isEqualTo: productId,
                                                    )
                                                    .get()
                                                    .catchError(
                                                      (_) =>
                                                          // ignore: invalid_return_type_for_catch_error
                                                          QuerySnapshotFake.empty(),
                                                    );
                                                for (var d in q3.docs)
                                                  fids.add(d.id);

                                                for (var fid in fids) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('feedbacks')
                                                      .doc(fid)
                                                      .delete();
                                                }
                                              } catch (_) {
                                                // ignore individual feedback delete errors
                                              }

                                              // After deleting, check if parent has items
                                              final rem =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('orders')
                                                      .where(
                                                        'parentOrderId',
                                                        isEqualTo: orderId,
                                                      )
                                                      .get();
                                              if (rem.docs.isEmpty) {
                                                await FirebaseFirestore.instance
                                                    .collection('orders')
                                                    .doc(orderId)
                                                    .delete();
                                              }

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "✅ Item deleted successfully",
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "❌ Failed to delete item: $e",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],
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

/// Helper fake class to return an empty QuerySnapshot safely in .catchError
class QuerySnapshotFake implements QuerySnapshot {
  QuerySnapshotFake._();
  static QuerySnapshot empty() => QuerySnapshotFake._();

  @override
  // ignore: todo
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
