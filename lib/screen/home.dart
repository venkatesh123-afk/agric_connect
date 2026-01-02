import 'package:agri_marketplace_app/buyer_dashboard.dart';
import 'package:agri_marketplace_app/farmer_dashboard.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required String userName,
    required String farmerId,
    required String buyerId,
  }); // ✅ removed unused parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to AgriConnect',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ✅ Farmer option
                  _buildCardOption(
                    context,
                    icon: Icons.agriculture,
                    label: "I'm a Farmer",
                    color: Colors.green,
                    onPressed: () {
                      Navigator.pushNamed(context, FarmerDashboard.routeName);
                    },
                  ),
                  const SizedBox(height: 20),

                  // ✅ Buyer option
                  _buildCardOption(
                    context,
                    icon: Icons.shopping_cart,
                    label: "I'm a Buyer",
                    color: Colors.green,
                    onPressed: () {
                      Navigator.pushNamed(context, BuyerDashboard.routeName);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
