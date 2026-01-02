import 'package:agri_marketplace_app/screen/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // ✅ EMAIL LOGIN + Firestore farmer/buyer check + save credentials
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCred.user!.uid;
      final farmerRef = _firestore.collection("farmers").doc(uid);
      final buyerRef = _firestore.collection("buyers").doc(uid);

      // Ensure farmer doc exists
      if (!(await farmerRef.get()).exists) {
        await farmerRef.set({
          "farmerId": uid,
          "name": userCred.user?.displayName ?? "Unnamed Farmer",
          "email": userCred.user?.email,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      // Ensure buyer doc exists
      if (!(await buyerRef.get()).exists) {
        await buyerRef.set({
          "buyerId": uid,
          "name": userCred.user?.displayName ?? "Unnamed Buyer",
          "email": userCred.user?.email,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      // ✅ Save credentials securely for biometric re-login
      await storage.write(key: "email", value: _emailController.text.trim());
      await storage.write(key: "password", value: _passwordController.text.trim());

      _goToHome(userCred.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else {
        errorMessage = 'Error: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ BIOMETRIC LOGIN with auto re-login using secure storage
  Future<void> _authenticateWithBiometrics({required bool faceOnly}) async {
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      if (!canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No biometric sensor found!")),
        );
        return;
      }

      final List<BiometricType> available = await auth.getAvailableBiometrics();

      if (faceOnly && !available.contains(BiometricType.face)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face Unlock not available on this device.")),
        );
        return;
      } 

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            faceOnly ? "Use Face ID to login" : "Authenticate with Biometrics",
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        // If already logged in → go home
        final user = _auth.currentUser;
        if (user != null) {
          _goToHome(user);
          return;
        }

        // Otherwise → try re-login with stored credentials
        final email = await storage.read(key: "email");
        final password = await storage.read(key: "password");

        if (email != null && password != null) {
          try {
            UserCredential cred = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            _goToHome(cred.user!);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Session expired. Please login manually.")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No saved session. Please login manually.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Biometric auth failed: $e")),
      );
    }
  }

  // ✅ Navigate to HomePage
  void _goToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          userName: user.displayName ?? "User",
          farmerId: user.uid,
          buyerId: user.uid,
        ),
      ),
    );
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
                    Hero(
                      tag: 'logo',
                      child: Image.asset('assets/logo.jpg', height: 100),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: 50,
                              color: Colors.green,
                            )
                          ],
                        ),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              _customPageRoute(const Signup()),
                            );
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      maxLength: 40,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        } else if (!RegExp(r'^[\w-\.]+@gmail\.com$')
                            .hasMatch(value)) {
                          return 'Email must end with @gmail.com';
                        } else if (value.length < 10) {
                          return 'Email must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock,
                      obscure: _obscurePassword,
                      maxLength: 20,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        } else if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Email login button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Log In"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fingerprint login
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _authenticateWithBiometrics(faceOnly: false),
                        icon: const Icon(Icons.fingerprint, color: Colors.green),
                        label: const Text("Log in with Biometrics"),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Route _customPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Reusable Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int maxLength,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
