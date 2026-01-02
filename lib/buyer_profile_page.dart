import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'login.dart';
import 'edit_profilebuyer.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  String _name = "";
  String _email = "";
  String _location = "";
  String? _profileImageUrl;
  XFile? _pickedImage;

  final ImagePicker _picker = ImagePicker();
  late String userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? "demoBuyer";
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("buyers")
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _name = data["name"] ?? "Buyer";
          _email = data["email"] ?? "buyer@example.com";
          _location = data["location"] ?? "Unknown";
          _profileImageUrl = data["profileImage"];
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _pickedImage = pickedFile);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("buyer_profile_images")
          .child(userId)
          .child("profile.jpg");

      UploadTask uploadTask = kIsWeb
          ? ref.putData(await pickedFile.readAsBytes())
          : ref.putFile(File(pickedFile.path));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("buyers").doc(userId).set({
        "name": _name,
        "email": _email,
        "location": _location,
        "profileImage": downloadUrl,
      }, SetOptions(merge: true));

      setState(() => _profileImageUrl = downloadUrl);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
    }
  }

  Future<void> _callUs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Call Support"),
        content: const Text("Do you want to call our support number?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Call"),
          ),
        ],
      ),
    );

    if (confirm != true || kIsWeb) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: '8374217410');
    if (await canLaunchUrl(phoneUri)) {
      launchUrl(phoneUri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse("https://wa.me/8374217410");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("WhatsApp not installed")));
    }
  }

  void _shareApp() {
    Share.share("Check out this Agri Marketplace app!");
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          name: _name,
          email: _email,
          location: _location,
          profileImage: _profileImageUrl,
          userId: userId,
        ),
      ),
    );
    if (updatedData != null && mounted) {
      setState(() {
        _name = updatedData["name"];
        _email = updatedData["email"];
        _location = updatedData["location"];
        _profileImageUrl = updatedData["profileImage"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Buyer Profile",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/buyer-dashboard'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------- Profile Header -------------------
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _pickedImage != null
                              ? (kIsWeb
                                    ? NetworkImage(_pickedImage!.path)
                                    : FileImage(File(_pickedImage!.path)))
                              : (_profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage("assets/profile.jpg")
                                          as ImageProvider),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _location,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ------------------- Tiles -------------------
                  _buildTile(Icons.edit, "Edit Profile", _openEditProfile),
                  _buildTile(
                    Icons.privacy_tip,
                    "Privacy Policy",
                    () => Navigator.pushNamed(context, "/PrivacyPolicy"),
                  ),
                  _buildTile(
                    Icons.description,
                    "Terms & Conditions",
                    () => Navigator.pushNamed(context, "/TermsAndConditions"),
                  ),
                  _buildTile(Icons.share, "Share App", _shareApp),
                  _buildTile(Icons.call, "Call Us", _callUs),
                  _buildTile(Icons.chat, "Chat on WhatsApp", _openWhatsApp),
                  _buildTile(Icons.logout, "Logout", () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
