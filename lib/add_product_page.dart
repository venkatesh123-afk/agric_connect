import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import 'farmer_dashboard.dart';

class AddProductPage extends StatefulWidget {
  final Product? existingProduct; // null = add, not null = edit

  const AddProductPage({
    super.key,
    this.existingProduct,
    required String existingProductId,
    required Map existingData,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      _nameCtrl.text = widget.existingProduct!.name;
      _priceCtrl.text = widget.existingProduct!.price.toString();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid price")));
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Upload image if selected
      String imageUrl = widget.existingProduct?.imageUrl ?? "";
      if (_imageFile != null) {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance.ref().child(
          "product_images/$fileName",
        );

        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(_imageFile!.path));
        }

        imageUrl = await ref.getDownloadURL();
      }

      // Get logged-in farmer UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please login first");

      // Unique product ID for new product
      final productId =
          widget.existingProduct?.id ??
          FirebaseFirestore.instance.collection("products").doc().id;

      // Create product object
      final product = Product(
        id: productId,
        name: _nameCtrl.text.trim(),
        description: widget.existingProduct?.description ?? "",
        price: price,
        imageUrl: imageUrl,
        farmerId: user.uid,
        createdAt: widget.existingProduct?.createdAt ?? Timestamp.now(),
        category: '',
        quantity: widget.existingProduct?.quantity ?? 0,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection("products")
          .doc(product.id)
          .set(product.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingProduct == null
                ? "✅ Product Added Successfully"
                : "✅ Product Updated Successfully",
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FarmerDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProduct != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Product" : "Add Product"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : (isEdit && widget.existingProduct!.imageUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.existingProduct!.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(child: Text("Tap to select image")),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price (e.g. 20.0)"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    onPressed: _saveProduct,
                    child: Text(isEdit ? "Update Product" : "Add Product"),
                  ),
          ],
        ),
      ),
    );
  }
}
