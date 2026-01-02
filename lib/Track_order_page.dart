import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackOrderPage extends StatelessWidget {
  final String orderId;

  TrackOrderPage({super.key, required this.orderId});

  // 🔹 Define the standard statuses in order
  final List<String> statuses = ["pending", "accepted", "shipped", "delivered"];

  // 🔹 Color for each status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Track Order"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final currentStatus =
              orderData["status"]?.toString().toLowerCase() ?? "pending";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Order ID: ${orderId.substring(0, 8)}...",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      final isCompleted =
                          statuses.indexOf(currentStatus) >= index;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? _getStatusColor(status)
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              if (index != statuses.length - 1)
                                Container(
                                  width: 4,
                                  height: 60,
                                  color: isCompleted
                                      ? _getStatusColor(status)
                                      : Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? _getStatusColor(status)
                                      : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isCompleted
                                    ? "Completed"
                                    : index == statuses.indexOf(currentStatus)
                                    ? "In Progress"
                                    : "Pending",
                                style: TextStyle(
                                  color: isCompleted
                                      ? _getStatusColor(status)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
