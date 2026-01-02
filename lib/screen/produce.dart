import 'package:flutter/material.dart';

class ProduceDetailScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final int quantity;
  final String sellerName;

  const ProduceDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.quantity,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // Optional: Show language selection
              // You can link this with your existing language selector
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Language switching coming soon!")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              "Price: ₹${price.toStringAsFixed(2)} / unit",
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 8),

            Text(
              "Available: $quantity kg",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            Text(
              "Seller: $sellerName",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            Row(
              children: const [
                Text("Rating: ", style: TextStyle(fontSize: 16)),
                Icon(Icons.star, color: Colors.orange),
                Icon(Icons.star, color: Colors.orange),
                Icon(Icons.star, color: Colors.orange),
                Icon(Icons.star_half, color: Colors.orange),
                Icon(Icons.star_border, color: Colors.orange),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text("Add to Cart"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
