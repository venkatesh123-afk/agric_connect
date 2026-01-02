import 'package:flutter/material.dart';
import 'package:agri_marketplace_app/shop.dart';
import 'package:agri_marketplace_app/buyer_profile_page.dart';
import 'package:agri_marketplace_app/my_orders_page.dart';

/// =====================
/// Buyer Dashboard
/// =====================
class BuyerDashboard extends StatefulWidget {
  static const routeName = '/buyer-dashboard';

  const BuyerDashboard({super.key});

  @override
  _BuyerDashboardState createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BuyerHomeContent(),
    const MyOrdersPage(),
    const BuyerProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// =====================
/// Buyer Home Content
/// =====================
class BuyerHomeContent extends StatelessWidget {
  const BuyerHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Buyer Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Welcome to Agri Marketplace",
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(179, 247, 235, 235),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 20),
            _buildSuggestedCrops(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: const AssetImage('assets/buyer.jpeg'),
            backgroundColor: Colors.green[700],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello, Buyer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find fresh produce at great prices.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShopPage(
                          selectedProduct: '',
                          selectedPrice: '',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Go to Shop'),
                ),
              ],
            ),
          ),
          const Icon(Icons.store, color: Colors.yellowAccent, size: 36),
        ],
      ),
    );
  }

  Widget _buildSuggestedCrops(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1.2),
            _buildProductTile(context, 'Fresh Tomatoes', Colors.red),
            _buildProductTile(context, 'Fresh Onion', Colors.purple),
            _buildProductTile(context, 'Sweet Potato', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, String name, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.3),
        child: Icon(Icons.shopping_bag, color: color),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShopPage(selectedProduct: name, selectedPrice: ''),
          ),
        );
      },
    );
  }
}
