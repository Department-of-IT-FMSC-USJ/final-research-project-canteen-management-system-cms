import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';

class AdminComplaintView extends StatelessWidget {
  const AdminComplaintView({super.key});

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as admin')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // 🔴 Red Status Bar
          Container(height: 67.5, color: Colors.red),

          // 🔲 App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 60,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔙 Back Button & Title
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_outlined,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Complaints &...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                // 👤 Account & Logout
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

          // 🔃 Scrollable Complaints Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading complaints'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No complaints found'));
                }

                final complaintsByCanteen =
                    <String, List<QueryDocumentSnapshot>>{};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final canteenName =
                      data['canteen_name'] as String? ?? 'Unknown';
                  complaintsByCanteen
                      .putIfAbsent(canteenName, () => [])
                      .add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: complaintsByCanteen.entries.map((entry) {
                    final canteenName = entry.key;
                    final complaints = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Canteen: $canteenName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...complaints.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final timestamp =
                                (data['timestamp'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            final complaintType =
                                data['complaint_type'] ?? 'Unknown';
                            final message = data['message'] ?? 'No message';
                            final imageUrl = data['image_url'] as String?;

                            return Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: $complaintType',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Message: $message'),
                                  Text('Submitted: ${timestamp.toLocal()}'),
                                  if (imageUrl != null &&
                                      imageUrl.isNotEmpty &&
                                      imageUrl != 'pending_upload' &&
                                      imageUrl != 'uploading')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Image.network(
                                        imageUrl,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Text(
                                                'Failed to load image',
                                              );
                                            },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
