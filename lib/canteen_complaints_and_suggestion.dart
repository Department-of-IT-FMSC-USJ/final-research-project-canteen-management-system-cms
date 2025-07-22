import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CanteenComplaintsAndSuggestions extends StatefulWidget {
  const CanteenComplaintsAndSuggestions({super.key});

  @override
  State<CanteenComplaintsAndSuggestions> createState() =>
      _CanteenComplaintsAndSuggestionsState();
}

class _CanteenComplaintsAndSuggestionsState
    extends State<CanteenComplaintsAndSuggestions> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _canteenName;

  Future<void> _fetchCanteenData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('canteens').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _canteenName = doc.data()?['canteen_name'] as String?;
          print('Fetched canteen name: $_canteenName');
        });
      } else {
        print('User ${user.uid} is not a canteen or document does not exist');
      }
    } else {
      print('No user is signed in');
    }
  }

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
  void initState() {
    super.initState();
    _fetchCanteenData();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view complaints'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
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
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Complaints &..',
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CanteenNotificationView(),
                          ),
                        );
                      },
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _canteenName != null
                  ? _firestore
                        .collection('complaints')
                        .where('canteen_name', isEqualTo: _canteenName)
                        .orderBy('timestamp', descending: true)
                        .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error fetching complaints: ${snapshot.error}');
                  return const Center(child: Text('Error loading complaints'));
                }
                if (_canteenName == null ||
                    _canteenName!.isEmpty ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No complaints or suggestions found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final complaints = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint =
                        complaints[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 20,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 255, 0, 0),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            complaint['complaint_type'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                complaint['message'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (complaint['image_url'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.network(
                                    complaint['image_url'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                  ),
                                ),
                              Text(
                                'By: ${complaint['username'] ?? 'Anonymous'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Time: ${complaint['timestamp'] is Timestamp ? complaint['timestamp'].toDate().toString() : complaint['timestamp']?.toString() ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
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
