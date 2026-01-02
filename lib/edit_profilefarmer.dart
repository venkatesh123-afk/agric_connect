import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String name;

  final String location;
  final String? profileImage;
  final String userId;

  const EditProfilePage({
    super.key,
    required this.name,
    
    required this.location,
    required this.profileImage,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;

  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  String? _profileImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _locationController = TextEditingController(text: widget.location);
    _profileImageUrl = widget.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _pickedImage = pickedFile);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? imageUrl = _profileImageUrl;

    // Upload new image if selected
    if (_pickedImage != null) {
      try {
        String fileName = "farmer_profile_${widget.userId}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child("farmer_profile_images").child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(await _pickedImage!.readAsBytes());
        } else {
          uploadTask = ref.putFile(File(_pickedImage!.path));
        }

        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint("Image upload failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image")),
        );
      }
    }

    // Save updated profile
    final updatedData = {
      "name": _nameController.text.trim(),
     
      "location": _locationController.text.trim(),
      "profileImage": imageUrl ?? "",
    };

    try {
      await FirebaseFirestore.instance
          .collection("farmers")
          .doc(widget.userId)
          .set(updatedData, SetOptions(merge: true));

      Navigator.pop(context, updatedData); // send updated data back
    } catch (e) {
      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _pickedImage != null
                            ? (kIsWeb
                                ? NetworkImage(_pickedImage!.path)
                                : FileImage(File(_pickedImage!.path)) as ImageProvider)
                            : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage("assets/profile.jpg")),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter your name" : null,
                    ),
                  
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter your location" : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 