import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';

class CanteenNotificationView extends StatefulWidget {
  const CanteenNotificationView({super.key});

  @override
  State<CanteenNotificationView> createState() =>
      _CanteenNotificationViewState();
}

class _CanteenNotificationViewState extends State<CanteenNotificationView> {
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as canteen')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔴 Fixed Red Status Bar
          Container(height: 67.5, color: Colors.red),

          // 🔲 Fixed App Bar - White with back arrow, profile, and logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 60,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Canteen Notifications',
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
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('canteens')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return const Center(child: Text('Error loading user data'));
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(child: Text('Canteen data not found'));
                }

                final roleData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (roleData == null || roleData['role'] != 'canteen') {
                  return const Center(
                    child: Text('Access denied. Canteens only.'),
                  );
                }

                final canteenName = roleData['canteen_name'] as String? ?? '';
                if (canteenName.isEmpty) {
                  return const Center(child: Text('Canteen name not found'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading notifications'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No notifications found'),
                      );
                    }

                    final relevantNotifications = snapshot.data!.docs.where((
                      doc,
                    ) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final recipientType =
                          data['recipient_type'] as String? ?? '';
                      if (recipientType == 'all_canteens' ||
                          recipientType == 'both') {
                        return true;
                      }
                      if (recipientType == 'specific_canteen') {
                        final notificationCanteenName =
                            data['canteen_name'] as String? ?? '';
                        return notificationCanteenName == canteenName;
                      }
                      return false;
                    }).toList();

                    if (relevantNotifications.isEmpty) {
                      return const Center(
                        child: Text('No relevant notifications found'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: relevantNotifications.length,
                      itemBuilder: (context, index) {
                        final doc = relevantNotifications[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final timestamp =
                            (data['timestamp'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        final message = data['message'] ?? 'No message';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            title: Text(message),
                            subtitle: Text('Sent: ${timestamp.toLocal()}'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
