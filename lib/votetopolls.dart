import 'package:canteenapp/studentnotification_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:canteenapp/vote_by_meal_time.dart';
import 'package:canteenapp/main.dart';

class VoteToPolls extends StatefulWidget {
  const VoteToPolls({super.key});

  @override
  State<VoteToPolls> createState() => _VoteToPollsState();
}

class _VoteToPollsState extends State<VoteToPolls> {
  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Select Canteen',
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
                                const StudentNotificationView(),
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
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Stream error: ${snapshot.error}'); // Log the error
                    return Center(
                      child: Text('Error loading canteens: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No canteens with polls available'),
                    );
                  }
                  // Extract unique canteen names with error handling
                  final canteenNames = snapshot.data!.docs
                      .map((doc) {
                        try {
                          return doc['canteen_name'] as String?;
                        } catch (e) {
                          print(
                            'Error accessing canteen_name in doc ${doc.id}: $e',
                          );
                          return null;
                        }
                      })
                      .where((name) => name != null)
                      .toSet()
                      .toList();
                  if (canteenNames.isEmpty) {
                    print('No valid canteen names found in data');
                    return const Center(
                      child: Text('No valid canteen names available'),
                    );
                  }
                  return ListView.builder(
                    itemCount: canteenNames.length,
                    itemBuilder: (context, index) {
                      String canteenName = canteenNames[index]!;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VoteByMealTime(canteenName: canteenName),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              canteenName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
