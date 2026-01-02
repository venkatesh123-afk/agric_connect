import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          """
By using this app, you agree to the following Terms & Conditions:

1. Acceptance of Terms:
   - By registering, you accept these terms.

2. Use of Services:
   - Services must be used legally.
   - Misuse of platform will result in account suspension.

3. User Responsibilities:
   - Provide accurate information
   - Respect other users on the platform

4. Limitation of Liability:
   - We are not liable for third-party issues or misuse.

5. Updates:
   - Terms may be updated, and continued use implies acceptance.

Thank you for using Agri Marketplace!
          """,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
