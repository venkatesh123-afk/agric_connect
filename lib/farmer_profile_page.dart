import 'dart:io';
import 'package:agri_marketplace_app/splash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'login.dart';
import 'edit_profilefarmer.dart';

class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({super.key});

  @override
  State<FarmerProfilePage> createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  String _name = "";
  String _location = "";
  String? _profileImageUrl;

  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  late String userId;
  bool _isLoading = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    // 🔐 SAFETY: user must be logged in
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      return;
    }

    userId = user.uid;
    _loadProfileData();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("farmers")
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name = data["name"] ?? "Farmer";
          _location = data["location"] ?? "Unknown";
          _profileImageUrl = data["profileImage"];
        });
      }
    } catch (e) {
      debugPrint("Error loading farmer profile: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ---------------- IMAGE PICK & UPLOAD ----------------
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _pickedImage = pickedFile);

    try {
      final ref = FirebaseStorage.instance.ref().child(
        "farmer_profile_images/$userId/profile.jpg",
      );

      UploadTask uploadTask = kIsWeb
          ? ref.putData(await pickedFile.readAsBytes())
          : ref.putFile(File(pickedFile.path));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("farmers").doc(userId).set({
        "name": _name,
        "location": _location,
        "profileImage": downloadUrl,
      }, SetOptions(merge: true));

      setState(() => _profileImageUrl = downloadUrl);
    } catch (e) {
      debugPrint("Image upload failed: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
    }
  }

  // ---------------- LOGOUT (IMPORTANT) ----------------
  Future<void> _logout() async {
    setState(() => _loggingOut = true);

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  // ---------------- ACTIONS ----------------
  Future<void> _callUs() async {
    if (kIsWeb) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: '+919876543210');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _shareApp() {
    Share.share("Check out this Agri Marketplace app!");
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          name: _name,
          location: _location,
          profileImage: _profileImageUrl,
          userId: userId,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      setState(() {
        _name = updatedData["name"];
        _location = updatedData["location"];
        _profileImageUrl = updatedData["profileImage"];
      });
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loggingOut) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Farmer Profile",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- PROFILE HEADER --------
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
                    Text(_location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            _buildProfileTile(
              icon: Icons.edit,
              title: "Edit Profile",
              onTap: _openEditProfile,
            ),
            _buildProfileTile(
              icon: Icons.privacy_tip,
              title: "Privacy Policy",
              onTap: () => Navigator.pushNamed(context, "/PrivacyPolicy"),
            ),
            _buildProfileTile(
              icon: Icons.description,
              title: "Terms & Conditions",
              onTap: () => Navigator.pushNamed(context, "/TermsAndConditions"),
            ),
            _buildProfileTile(
              icon: Icons.share,
              title: "Share App",
              onTap: _shareApp,
            ),
            _buildProfileTile(
              icon: Icons.call,
              title: "Call Us",
              onTap: _callUs,
            ),
            _buildProfileTile(
              icon: Icons.logout,
              title: "Logout",
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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
