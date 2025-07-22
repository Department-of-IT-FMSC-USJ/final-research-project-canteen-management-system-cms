import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart'; // Import your main.dart file
import 'package:canteenapp/phi_suggestion_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PhiPage extends StatelessWidget {
  const PhiPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate back to login page and clear the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      // Show error message if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _contactAdmin(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 16),
              Text('Getting admin contact...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Get admin phone number from Firestore
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('phone_number', isNotEqualTo: '')
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        print('No admins with phone number found in Firestore'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin contact not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get phone number from first admin document
      final adminData = adminSnapshot.docs.first.data() as Map<String, dynamic>;
      String phoneNumber = adminData['phone_number'] ?? '';

      if (phoneNumber.isEmpty) {
        print('Admin phone number is empty or null'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin phone number not available'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Clean the phone number (remove spaces, dashes, etc., except +)
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Convert local Sri Lankan number (07 followed by 7 or 8 digits) to international format
      final localNumberRegex = RegExp(r'^07\d{7,8}$');
      final dialNumber = localNumberRegex.hasMatch(phoneNumber)
          ? '+94${phoneNumber.substring(1)}' // Convert 0774563456 to +94774563456
          : phoneNumber;

      print('Attempting to dial: $dialNumber'); // Debug log
      final Uri phoneUri = Uri(scheme: 'tel', path: dialNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('Phone call launched successfully'); // Debug log
      } else {
        print('Cannot launch dialer for: $dialNumber'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone calling not supported on this device'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error contacting admin: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error contacting admin: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔴 Fixed Red Status Bar
          Container(height: 67.5, color: Colors.red),

          // 🔲 Fixed App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 60,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.menu, color: Colors.black, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'PHI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.account_circle,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔃 Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Logo
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/logo.png',
                      height: 130,
                      width: 130,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    'University Canteen\nManagement System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhiSuggestionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      minimumSize: const Size(360, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Submit Complaints & Suggestions',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _contactAdmin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      minimumSize: const Size(360, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Contact Admin',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
