import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CanteenFeedback extends StatefulWidget {
  const CanteenFeedback({super.key});

  @override
  State<CanteenFeedback> createState() => _CanteenFeedbackState();
}

class _CanteenFeedbackState extends State<CanteenFeedback> {
  String? _canteenName;

  @override
  void initState() {
    super.initState();
    _fetchCanteenName();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }

  Future<void> _fetchCanteenName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('canteens') // Using 'canteens' collection
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _canteenName = userDoc.data()?['canteen_name'] as String?;
        });
      } else {
        print('No canteens document found for uid: ${user.uid}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_canteenName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Canteen Feedback',
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
                            builder: (context) => CanteenNotificationView(),
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
              stream: FirebaseFirestore.instance
                  .collection('meals')
                  .where('canteen_name', isEqualTo: _canteenName)
                  .snapshots()
                  .asyncMap((mealsSnapshot) async {
                    final mealIds = mealsSnapshot.docs
                        .map((doc) => doc.id)
                        .toList();
                    if (mealIds.isEmpty) {
                      print('No meals found');
                      return FirebaseFirestore.instance
                          .collection('feedback')
                          .where('meal_id', whereIn: [''])
                          .snapshots();
                    }
                    return FirebaseFirestore.instance
                        .collection('feedback')
                        .where('meal_id', whereIn: mealIds)
                        .snapshots();
                  })
                  .asyncExpand((stream) => stream),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return const Center(child: Text('Error loading feedback'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No feedback data');
                  return const Center(child: Text('No feedback available'));
                }

                final feedbackDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: feedbackDocs.length,
                  itemBuilder: (context, index) {
                    final feedback =
                        feedbackDocs[index].data() as Map<String, dynamic>;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('meals')
                          .doc(feedback['meal_id'])
                          .get(),
                      builder: (context, mealSnapshot) {
                        if (mealSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        if (mealSnapshot.hasError || !mealSnapshot.hasData) {
                          return const ListTile(title: Text('Meal not found'));
                        }

                        final meal =
                            mealSnapshot.data!.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 2.0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(meal['meal_name'] ?? 'Unnamed Meal'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rating: ${feedback['rating']}'),
                                Text(
                                  'Comment: ${feedback['comment'] ?? 'No comment'}',
                                ),
                                Text(
                                  'Time: ${feedback['timestamp']?.toDate().toString() ?? 'N/A'}',
                                ),
                              ],
                            ),
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
