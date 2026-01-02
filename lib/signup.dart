import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Create Firebase Auth account
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCred.user;
      if (user != null) {
        // ✅ Update FirebaseAuth displayName
        await user.updateDisplayName(_nameController.text.trim());

        // Common user info
        final userData = {
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        };

        // ✅ Use batch write so all docs are created atomically
        WriteBatch batch = _firestore.batch();

        // General users collection
        final userDoc = _firestore.collection("users").doc(user.uid);
        batch.set(userDoc, {
          ...userData,
          "roles": ["buyer", "farmer"],
        });

        // Farmer profile
        final farmerDoc = _firestore.collection("farmers").doc(user.uid);
        batch.set(farmerDoc, {
          "farmerId": user.uid,
          ...userData,
        });

        // Buyer profile
        final buyerDoc = _firestore.collection("buyers").doc(user.uid);
        batch.set(buyerDoc, {
          "buyerId": user.uid,
          ...userData,
        });

        await batch.commit();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      // ✅ Navigate back to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11CB74), Color(0xFF25FC42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Hero(tag: 'logo', child: Image.asset('assets/logo.jpg', height: 100)),
                    const SizedBox(height: 10),
                    const Text(
                      "Create an Account!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildInputField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person,
                      maxLength: 35,
                      validator: (v) => v == null || v.isEmpty
                          ? "Name is required"
                          : v.length < 3
                              ? "Name must be at least 3 characters"
                              : null,
                    ),
                    const SizedBox(height: 18),

                    _buildInputField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      maxLength: 50,
                      validator: (v) => v == null || v.isEmpty
                          ? "Email is required"
                          : !RegExp(r'^[\w-\.]+@[\w-]+\.[a-z]{2,}$').hasMatch(v)
                              ? "Enter a valid email"
                              : null,
                    ),
                    const SizedBox(height: 18),

                    _buildInputField(
                      controller: _phoneController,
                      label: "Phone",
                      icon: Icons.phone,
                      maxLength: 10,
                      validator: (v) => v == null || v.isEmpty
                          ? "Phone is required"
                          : v.length != 10
                              ? "Enter a valid phone number"
                              : null,
                    ),
                    const SizedBox(height: 18),

                    _buildInputField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock,
                      obscure: _obscurePassword,
                      maxLength: 20,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? "Password is required"
                          : v.length < 6
                              ? "Password must be at least 6 characters"
                              : null,
                    ),
                    const SizedBox(height: 18),

                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      maxLength: 20,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (v) => v != _passwordController.text
                          ? "Passwords do not match"
                          : null,
                    ),
                    const SizedBox(height: 30),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _handleEmailSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Sign Up",
                                style: TextStyle(fontSize: 18)),
                          ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Already have an account? Log in",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    int? maxLength,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        counterText: "",
      ),
      validator: validator,
    );
  }
}
