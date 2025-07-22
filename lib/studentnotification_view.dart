import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';

class StudentNotificationView extends StatelessWidget {
  const StudentNotificationView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a student')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(height: 67.5, color: Colors.red),

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
                        Icons.arrow_back_ios_new_outlined,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Notifications',
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
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  print('User Doc Error: ${userSnapshot.error}'); // Debug log
                  return const Center(child: Text('Error loading user data'));
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  print('User Doc Not Found: UID ${user.uid}'); // Debug log
                  return const Center(child: Text('Student data not found'));
                }

                final roleData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (roleData == null ||
                    (roleData['role'] != null &&
                        roleData['role'] != 'student')) {
                  print('Role Data: $roleData'); // Debug role data
                  return const Center(
                    child: Text('Access denied. Students only.'),
                  );
                }

                // Get student's preferred canteen, if any
                final preferredCanteen =
                    roleData['preferred_canteen'] as String?;

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
                      print('Firestore Error: ${snapshot.error}'); // Debug log
                      return const Center(
                        child: Text('Error loading notifications'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('No notifications found in Firestore'); // Debug log
                      return const Center(
                        child: Text('No notifications found'),
                      );
                    }

                    final relevantNotifications = snapshot.data!.docs.where((
                      doc,
                    ) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final recipientType =
                          (data['recipient_type'] as String? ?? '')
                              .toLowerCase();
                      print(
                        'Checking notification: ID=${doc.id}, recipientType=$recipientType, canteen_name=${data['canteen_name']}',
                      ); // Debug each notification

                      // Include notifications for 'students' or 'both'
                      if (recipientType == 'students' ||
                          recipientType == 'both') {
                        print('Matched: $recipientType'); // Debug match
                        return true;
                      }
                      // Include 'specific_canteen' notifications if the student has a preferred canteen
                      if (recipientType == 'specific_canteen' &&
                          preferredCanteen != null &&
                          data['canteen_name'] == preferredCanteen) {
                        print(
                          'Matched: specific_canteen for $preferredCanteen',
                        ); // Debug match
                        return true;
                      }
                      print(
                        'Skipped: $recipientType not relevant',
                      ); // Debug skip
                      return false;
                    }).toList();

                    print(
                      'Relevant Notifications count: ${relevantNotifications.length}',
                    ); // Debug filtered count

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
                        final recipientType =
                            data['recipient_type'] ?? 'Unknown';
                        final canteenName = data['canteen_name'] ?? '';
                        final subtitle = recipientType == 'specific_canteen'
                            ? 'To: $canteenName\nSent: ${timestamp.toLocal()}'
                            : 'Sent: ${timestamp.toLocal()}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            title: Text(message),
                            subtitle: Text(subtitle),
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
