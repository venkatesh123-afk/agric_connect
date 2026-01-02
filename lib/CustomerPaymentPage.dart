import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import 'buyer_dashboard.dart';
// Removed success_screen navigation; now returns to buyer dashboard

class CustomerPaymentPage extends StatefulWidget {
  final double totalAmount;
  final Map<String, dynamic> address;
  final Map<Product, int> orderItems; // Product → Qty
  final List<Product> cartItems; // Full cart
  final String orderId;

  const CustomerPaymentPage({
    super.key,
    required this.totalAmount,
    required this.address,
    required this.orderItems,
    required this.cartItems,
    required this.orderId,
  });

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  String? selectedPaymentMethod;
  bool _isProcessing = false;

  // Additional payment details
  String? selectedUpiApp;
  String? selectedBank;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  final List<String> checkoutSteps = ["Address", "Order Summary", "Payment"];
  final int currentStep = 2;

  final List<Map<String, dynamic>> paymentOptions = [
    {
      "icon": Icons.account_balance_wallet,
      "title": "UPI Payment",
      "method": "UPI",
      "color": Colors.teal,
      "subtitle": "PhonePe, Google Pay, Paytm",
    },
    {
      "icon": Icons.credit_card,
      "title": "Credit / Debit Card",
      "method": "Card",
      "color": Colors.indigo,
      "subtitle": "Visa, Mastercard, RuPay",
    },
    {
      "icon": Icons.account_balance,
      "title": "Net Banking",
      "method": "NetBank",
      "color": Colors.green,
      "subtitle": "All major banks",
    },
    {
      "icon": Icons.local_shipping_outlined,
      "title": "Cash on Delivery",
      "method": "COD",
      "color": Colors.brown,
      "subtitle": "Pay when delivered",
    },
  ];

  // UPI apps list
  final List<Map<String, dynamic>> upiApps = [
    {"name": "PhonePe", "icon": "📱", "color": Colors.purple},
    {"name": "Google Pay", "icon": "💳", "color": Colors.blue},
    {"name": "Paytm", "icon": "💰", "color": Colors.indigo},
    {"name": "BHIM", "icon": "🏦", "color": Colors.orange},
    {"name": "Amazon Pay", "icon": "🛒", "color": Colors.amber},
    {"name": "WhatsApp Pay", "icon": "💬", "color": Colors.green},
  ];

  // Net Banking banks list
  final List<Map<String, dynamic>> banks = [
    {"name": "State Bank of India", "code": "SBI"},
    {"name": "HDFC Bank", "code": "HDFC"},
    {"name": "ICICI Bank", "code": "ICICI"},
    {"name": "Axis Bank", "code": "AXIS"},
    {"name": "Kotak Mahindra Bank", "code": "KOTAK"},
    {"name": "Punjab National Bank", "code": "PNB"},
    {"name": "Bank of Baroda", "code": "BOB"},
    {"name": "Canara Bank", "code": "CANARA"},
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  /// 🔹 Payment processing
  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please select a payment method")),
      );
      return;
    }

    // Validate additional payment details
    if (selectedPaymentMethod == "UPI" && selectedUpiApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please select a UPI app")),
      );
      return;
    }

    if (selectedPaymentMethod == "Card") {
      if (_cardNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Please enter cardholder name")),
        );
        return;
      }
      if (_cardNumberController.text.replaceAll(' ', '').length < 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Please enter valid card number")),
        );
        return;
      }
      if (_expiryController.text.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Please enter valid expiry date")),
        );
        return;
      }
      if (_cvvController.text.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ Please enter valid CVV")),
        );
        return;
      }
    }

    if (selectedPaymentMethod == "NetBank" && selectedBank == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠ Please select a bank")));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) throw "User not logged in";

      final txnId = "TXN${DateTime.now().millisecondsSinceEpoch}";

      final orderRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId);

      // Update main order document with payment info
      await orderRef.update({
        "status": selectedPaymentMethod == "COD" ? "Pending" : "Paid",
        "paymentMethod": selectedPaymentMethod,
        "paymentCompletedAt": FieldValue.serverTimestamp(),
      });

      // Update all product orders with payment status
      final productOrdersSnapshot = await FirebaseFirestore.instance
          .collection("orders")
          .where("parentOrderId", isEqualTo: widget.orderId)
          .get();

      for (final doc in productOrdersSnapshot.docs) {
        await doc.reference.update({
          "status": selectedPaymentMethod == "COD" ? "Pending" : "Paid",
          "paymentMethod": selectedPaymentMethod,
          "paymentCompletedAt": FieldValue.serverTimestamp(),
        });
      }

      // 3️⃣ Save payment record with additional details
      Map<String, dynamic> paymentData = {
        "transactionId": txnId,
        "orderId": widget.orderId,
        "buyerId": buyerId,
        "amount": widget.totalAmount,
        "method": selectedPaymentMethod,
        "paidAt": FieldValue.serverTimestamp(),
        "status": selectedPaymentMethod == "COD" ? "Pending" : "Paid",
        "buyerAddress": widget.address,
      };

      // Add payment method specific details
      if (selectedPaymentMethod == "UPI") {
        paymentData["upiApp"] = selectedUpiApp;
      } else if (selectedPaymentMethod == "Card") {
        paymentData["cardLastFour"] = _cardNumberController.text
            .replaceAll(' ', '')
            .substring(
              _cardNumberController.text.replaceAll(' ', '').length - 4,
            );
        paymentData["cardholderName"] = _cardNameController.text;
        paymentData["expiryDate"] = _expiryController.text;
      } else if (selectedPaymentMethod == "NetBank") {
        paymentData["bankCode"] = selectedBank;
        paymentData["bankName"] = banks.firstWhere(
          (bank) => bank["code"] == selectedBank,
        )["name"];
      }

      await FirebaseFirestore.instance
          .collection("payments")
          .doc(txnId)
          .set(paymentData);

      if (!mounted) return;

      // ✅ Navigate back to buyer dashboard home after payment
      Navigator.pushNamedAndRemoveUntil(
        context,
        BuyerDashboard.routeName,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Payment failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// 🔹 Checkout progress indicator
  Widget _buildCheckoutHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(checkoutSteps.length, (index) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? Colors.green
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= currentStep
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkoutSteps[index],
                  style: TextStyle(
                    color: index <= currentStep
                        ? Colors.green
                        : Colors.grey[600],
                    fontWeight: index == currentStep
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 🔹 Payment option card
  Widget _buildPaymentOption(Map<String, dynamic> option) {
    final isSelected = selectedPaymentMethod == option["method"];
    final color = option["color"] as Color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(option["icon"], color: isSelected ? Colors.blue : color),
        title: Text(
          option["title"],
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
        subtitle: Text(
          option["subtitle"] ?? "",
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
        onTap: () {
          setState(() {
            selectedPaymentMethod = option["method"];
            // Reset additional selections when changing payment method
            selectedUpiApp = null;
            selectedBank = null;
          });
        },
      ),
    );
  }

  /// 🔹 UPI Payment Details
  Widget _buildUpiPaymentDetails() {
    if (selectedPaymentMethod != "UPI") return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select UPI App",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: upiApps.map((app) {
                final isSelected = selectedUpiApp == app["name"];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedUpiApp = app["name"];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(app["icon"], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          app["name"],
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedUpiApp != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You will be redirected to $selectedUpiApp to complete the payment",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🔹 Card Payment Details
  Widget _buildCardPaymentDetails() {
    if (selectedPaymentMethod != "Card") return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Card Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(
                labelText: "Cardholder Name",
                hintText: "Enter full name as on card",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Card Number",
                hintText: "1234 5678 9012 3456",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              maxLength: 19,
              onChanged: (value) {
                // Format card number with spaces
                String formatted = value.replaceAll(RegExp(r'\D'), '');
                String formattedWithSpaces = '';
                for (int i = 0; i < formatted.length; i++) {
                  if (i > 0 && i % 4 == 0) formattedWithSpaces += ' ';
                  formattedWithSpaces += formatted[i];
                }
                if (formattedWithSpaces != value) {
                  _cardNumberController.value = TextEditingValue(
                    text: formattedWithSpaces,
                    selection: TextSelection.collapsed(
                      offset: formattedWithSpaces.length,
                    ),
                  );
                }
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: "MM/YY",
                      hintText: "12/25",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    maxLength: 5,
                    onChanged: (value) {
                      // Format expiry date
                      String formatted = value.replaceAll(RegExp(r'\D'), '');
                      if (formatted.length >= 2) {
                        formatted =
                            '${formatted.substring(0, 2)}/${formatted.substring(2)}';
                      }
                      if (formatted != value) {
                        _expiryController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      hintText: "123",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    maxLength: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Net Banking Details
  Widget _buildNetBankingDetails() {
    if (selectedPaymentMethod != "NetBank") return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Bank",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBank,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Choose your bank"),
                  ),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: banks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank["code"],
                      child: Text(bank["name"]),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedBank = value;
                    });
                  },
                ),
              ),
            ),
            if (selectedBank != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You will be redirected to secure bank page for payment",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckoutHeader(),
          const Divider(),
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  "₹${widget.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                // Payment method options
                ...paymentOptions.map(_buildPaymentOption),

                // Payment details based on selected method
                _buildUpiPaymentDetails(),
                _buildCardPaymentDetails(),
                _buildNetBankingDetails(),

                // COD Info
                if (selectedPaymentMethod == "COD")
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            color: Colors.brown,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Cash on Delivery",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  "Pay when your order is delivered",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.green,
          ),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  "Pay ₹${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
