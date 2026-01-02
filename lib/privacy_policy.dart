import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          """
Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information.

1. Information We Collect:
   - Personal details (Name, Email, Location)
   - Usage data and preferences

2. How We Use Information:
   - To improve services
   - To provide better user experience
   - To send important updates

3. Data Protection:
   - We ensure strict security measures
   - Your data is not shared with third parties without consent

4. Contact Us:
   If you have any questions about this Privacy Policy, please reach out via support@agrimarketplace.com
          """,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
