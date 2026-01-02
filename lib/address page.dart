import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/product.dart';
import 'OrderSummaryPage.dart';

class CustomerAddressPage extends StatefulWidget {
  final Map<String, int> orderItems;
  final double totalAmount;
  final List<Product> cartItems;

  const CustomerAddressPage({
    super.key,
    required this.orderItems,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<CustomerAddressPage> createState() => _CustomerAddressPageState();
}

class _CustomerAddressPageState extends State<CustomerAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  Map<String, dynamic>? _savedAddress;
  bool _useSavedAddress = false;

  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedSavedAddressId;

  double? _currentLat;
  double? _currentLng;
  String? _staticMapUrl;

  static const String googleMapsApiKey = "YOUR_API_KEY";

  final List<String> checkoutSteps = ['Address', 'Order Summary', 'Payment'];
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadLastAddress();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLastAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final query = await FirebaseFirestore.instance
        .collection('address')
        .where('buyerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      _savedAddress = {'id': query.docs.first.id, ...data};
      _useSavedAddress = true;
      _populateFormWithAddress(_savedAddress!);
      setState(() {});
    }
  }

  Future<void> _loadSavedAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final query = await FirebaseFirestore.instance
        .collection('address')
        .where('buyerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    _savedAddresses = query.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    setState(() {});
  }

  void _populateFormWithAddress(Map<String, dynamic> addr) {
    _nameCtrl.text = addr['name'] ?? '';
    _phoneCtrl.text = addr['phone'] ?? '';
    _streetCtrl.text = addr['street'] ?? '';
    _cityCtrl.text = addr['city'] ?? '';
    _stateCtrl.text = addr['state'] ?? '';
    _pincodeCtrl.text = addr['pincode'] ?? '';
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied permanently.'),
          ),
        );
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final streetParts = <String?>[p.street, p.subLocality];
        _streetCtrl.text = streetParts
            .where((s) => (s ?? '').isNotEmpty)
            .join(', ')
            .trim();
        _cityCtrl.text = p.locality ?? '';
        _stateCtrl.text = p.administrativeArea ?? '';
        _pincodeCtrl.text = p.postalCode ?? '';
        _nameCtrl.text = _nameCtrl.text.isEmpty
            ? "My Location"
            : _nameCtrl.text;
      }

      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _staticMapUrl =
          "https://maps.googleapis.com/maps/api/staticmap?center=$_currentLat,$_currentLng"
          "&zoom=16&size=600x300&markers=color:red%7C$_currentLat,$_currentLng"
          "&key=$googleMapsApiKey";

      final tempAddress = {
        'id': 'temp',
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'street': _streetCtrl.text,
        'city': _cityCtrl.text,
        'state': _stateCtrl.text,
        'pincode': _pincodeCtrl.text,
        'temp': true,
      };

      setState(() {
        _savedAddresses.removeWhere((a) => a['id'] == 'temp');
        _savedAddresses.insert(0, tempAddress);
        _selectedSavedAddressId = 'temp';
        _savedAddress = tempAddress;
        _useSavedAddress = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location detected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance
          .collection('address')
          .doc(addressId)
          .delete();
      await _loadSavedAddresses();
      if (_selectedSavedAddressId == addressId) {
        setState(() {
          _selectedSavedAddressId = null;
          _savedAddress = null;
          _useSavedAddress = false;
          _nameCtrl.clear();
          _phoneCtrl.clear();
          _streetCtrl.clear();
          _cityCtrl.clear();
          _stateCtrl.clear();
          _pincodeCtrl.clear();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete address: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _saveAddressToFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw "User not logged in";

    final addressData = {
      'buyerId': uid,
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'street': _streetCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'pincode': _pincodeCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_selectedSavedAddressId != null && _selectedSavedAddressId != 'temp') {
      await FirebaseFirestore.instance
          .collection('address')
          .doc(_selectedSavedAddressId)
          .update(addressData);
      return _selectedSavedAddressId!;
    } else {
      final docRef = await FirebaseFirestore.instance
          .collection('address')
          .add(addressData);
      return docRef.id;
    }
  }

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
          bool active = index <= currentStep;
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
                  checkoutSteps[index],
                  style: TextStyle(
                    color: active ? Colors.green : Colors.grey[600],
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

  Widget _buildSavedAddressBanner() {
    if (_savedAddress == null) return const SizedBox.shrink();
    final addr = _savedAddress!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                _useSavedAddress
                    ? 'Deliver to (Saved Address)'
                    : 'Saved Address',
                style: TextStyle(
                  color: Colors.green[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_useSavedAddress)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useSavedAddress = false; // enable editing
                    });
                  },
                  child: const Text('Change address'),
                )
              else
                TextButton(
                  onPressed: () {
                    _populateFormWithAddress(addr);
                    setState(() {
                      _useSavedAddress = true;
                    });
                  },
                  child: const Text('Use saved address'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            addr['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('${addr['street'] ?? ''}'),
          Text(
            '${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pincode'] ?? ''}',
          ),
          const SizedBox(height: 2),
          Text('Phone: ${addr['phone'] ?? ''}'),
        ],
      ),
    );
  }

  void _continueToSummary() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final addressId = await _saveAddressToFirebase();

      final address = {
        "id": addressId,
        "name": _nameCtrl.text,
        "phone": _phoneCtrl.text,
        "street": _streetCtrl.text,
        "city": _cityCtrl.text,
        "state": _stateCtrl.text,
        "pincode": _pincodeCtrl.text,
      };

      final productOrderItems = <Product, int>{};
      widget.orderItems.forEach((productId, quantity) {
        final product = widget.cartItems.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: productId,
            name: "Unknown Product",
            description: '',
            price: 0.0,
            category: '',
            imageUrl: '',
            farmerId: '',
            createdAt: Timestamp.now(),
            quantity: 0,
          ),
        );
        productOrderItems[product] = quantity;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSummaryPage(
            orderItems: productOrderItems,
            totalAmount: widget.totalAmount,
            address: address,
            cartItems: [],
            currentStep: 1,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to save address: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Address"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildCheckoutHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildSavedAddressBanner(),
                    if (_savedAddresses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Other Saved Addresses",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ..._savedAddresses.map((a) {
                        final id = a['id'] as String;
                        if (_savedAddress != null &&
                            id == _savedAddress!['id']) {
                          return const SizedBox.shrink(); // skip banner address
                        }
                        final isTemp = a['temp'] == true;
                        final title =
                            '${a['name'] ?? ''} • ${a['phone'] ?? ''}';
                        final addrLine =
                            '${a['street'] ?? ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''} - ${a['pincode'] ?? ''}';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: RadioListTile<String>(
                            value: id,
                            groupValue: _selectedSavedAddressId,
                            onChanged: (val) {
                              _populateFormWithAddress(a);
                              setState(() {
                                _selectedSavedAddressId = val;
                                _savedAddress = a;
                                _useSavedAddress = true;
                              });
                            },
                            title: Row(
                              children: [
                                if (isTemp)
                                  const Icon(
                                    Icons.my_location,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                if (isTemp) const SizedBox(width: 4),
                                Expanded(child: Text(title)),
                              ],
                            ),
                            subtitle: Text(addrLine),
                            secondary: isTemp
                                ? const SizedBox.shrink()
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Delete Address"),
                                          content: const Text(
                                            "Are you sure you want to delete this address?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteAddress(id);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _useCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use current location'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // FORM FIELDS
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter name";
                        if (v.length > 20) return "Name must be <= 20 letters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter phone number";
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                          return "Phone must be exactly 10 digits";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetCtrl,
                      decoration: const InputDecoration(
                        labelText: "Street Address",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter street" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: "City",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter city" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(
                        labelText: "State",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter state" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Pincode",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter pincode";
                        if (!RegExp(r'^\d+$').hasMatch(v)) {
                          return "Pincode must be numbers only";
                        }
                        return null;
                      },
                    ),
                    if (_staticMapUrl != null) ...[const SizedBox(height: 20)],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueToSummary,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Continue to Order Summary",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
