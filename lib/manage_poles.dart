import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/add_items_on_options.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class ManagePoles extends StatefulWidget {
  const ManagePoles({super.key});

  @override
  State<ManagePoles> createState() => _ManagePolesState();
}

class _ManagePolesState extends State<ManagePoles> {
  String? userCanteenName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserCanteenName();
  }

  Future<void> _getUserCanteenName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('canteens')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            userCanteenName = data?['canteen_name'];
            print('Fetched canteen name: $userCanteenName');
            isLoading = false;
          });
        } else {
          setState(() {
            userCanteenName = null;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Canteen information not found. Ensure you are logged in as a canteen user and the canteens/{uid} document exists.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user found. Please log in.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    }
  }

  Future<void> _deletePole(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('polls').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting poll: $e')));
    }
  }

  void _showDeleteConfirmation(
    String docId,
    String mealTime,
    String optionNumber,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Poll'),
          content: Text(
            'Are you sure you want to delete $mealTime - $optionNumber?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePole(docId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editPole(Map<String, dynamic> pollData, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemsOnOptions(
          canteenName: pollData['canteen_name'],
          mealTime: pollData['meal_time'],
          optionNumber: pollData['option_number'],
          isEditing: true,
          existingItems: List<String>.from(pollData['items'] ?? []),
          pollId: docId,
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userCanteenName == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Could not load canteen information')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(height: 67.5, color: Colors.red),
          Container(
            padding: const EdgeInsets.only(left: 0),
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
                      'Manage Polls',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('polls')
                    .where('canteen_name', isEqualTo: userCanteenName)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Stream error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('No data or empty: userCanteenName=$userCanteenName');
                    return const Center(
                      child: Text(
                        'No polls created yet.\nCreate some polls to manage them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  print('Data loaded: ${snapshot.data!.docs.length} polls');
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      int voteCount = data['votes'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${data['meal_time']} - ${data['option_number']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _editPole(data, doc.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmation(
                                              doc.id,
                                              data['meal_time'],
                                              data['option_number'],
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Items:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...((data['items'] as List<dynamic>?) ?? [])
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    int idx = entry.key;
                                    String item = entry.value as String;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        bottom: 2,
                                      ),
                                      child: Text(
                                        '${idx + 1}. $item',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }),
                              const SizedBox(height: 8),
                              Text(
                                'Votes: $voteCount',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Created: ${data['created_at'] != null ? (data['created_at'] as Timestamp).toDate().toString().split('.')[0] : 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
