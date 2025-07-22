import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:canteenapp/student_feedback.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_feedback.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:canteenapp/studentnotification_view.dart';

class CanteenMenu extends StatelessWidget {
  const CanteenMenu({super.key});

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
    );
  }

  Widget foodCard(
    BuildContext context,
    String name,
    Uint8List? imageBytes,
    String price,
    double rating,
    String docId,
    Color? bordercolor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentFeedback(docId: docId),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: bordercolor ?? const Color.fromARGB(255, 255, 0, 0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.grey, spreadRadius: 2, blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 5),
            imageBytes != null
                ? Image.memory(
                    imageBytes,
                    height: 80,
                    width: 90,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 80),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. $price',
              style: const TextStyle(fontSize: 14, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RatingBarIndicator(
                    rating: rating.clamp(0.0, 5.0),
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 20,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view menu'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
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
                      'Canteen Menu',
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
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('canteens')
                          .doc(user.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final role =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (role?['role'] == 'canteen') {
                            return IconButton(
                              icon: const Icon(Icons.feedback),
                              color: Colors.black,
                              iconSize: 30,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CanteenFeedback(),
                                  ),
                                );
                              },
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return const Center(child: Text('Error loading menu'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No data or empty meals collection');
                  return const Center(child: Text('No meals available'));
                }

                final mealsByCanteen = <String, List<QueryDocumentSnapshot>>{};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data != null && data['canteen_name'] != null) {
                    mealsByCanteen
                        .putIfAbsent(data['canteen_name'] as String, () => [])
                        .add(doc);
                  } else {
                    print(
                      'Invalid or missing canteen_name for document: ${doc.id}',
                    );
                  }
                }
                print('Meals by canteen: $mealsByCanteen');

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: mealsByCanteen.entries.map((entry) {
                        final canteenName = entry.key;
                        final meals = entry.value;
                        return _buildCanteenSection(
                          context,
                          canteenName,
                          meals,
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanteenSection(
    BuildContext context,
    String canteenName,
    List<QueryDocumentSnapshot> meals,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          height: 50,
          width: 370,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              canteenName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .where('meal_id', whereIn: meals.map((doc) => doc.id).toList())
                .snapshots(),
            builder: (context, feedbackSnapshot) {
              if (feedbackSnapshot.hasError) {
                print('Feedback stream error: ${feedbackSnapshot.error}');
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: meals.map((doc) {
                      final meal = doc.data() as Map<String, dynamic>;
                      final imageData = meal['image'];
                      Uint8List? imageBytes =
                          imageData != null && imageData is Uint8List
                          ? imageData
                          : null;
                      return foodCard(
                        context,
                        meal['meal_name'] as String,
                        imageBytes,
                        meal['price'].toString(),
                        0.0,
                        doc.id,
                        const Color.fromARGB(255, 0, 0, 0),
                      );
                    }).toList(),
                  ),
                );
              }
              if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: meals.map((doc) {
                      final meal = doc.data() as Map<String, dynamic>;
                      final imageData = meal['image'];
                      Uint8List? imageBytes =
                          imageData != null && imageData is Uint8List
                          ? imageData
                          : null;
                      return foodCard(
                        context,
                        meal['meal_name'] as String,
                        imageBytes,
                        meal['price'].toString(),
                        0.0,
                        doc.id,
                        const Color.fromARGB(255, 0, 0, 0),
                      );
                    }).toList(),
                  ),
                );
              }

              final feedbackData = feedbackSnapshot.data?.docs ?? [];
              final ratingsMap = <String, List<double>>{};
              for (var doc in feedbackData) {
                final data = doc.data() as Map<String, dynamic>;
                final mealId = data['meal_id'] as String;
                final rating = (data['rating'] as num? ?? 0).toDouble();
                ratingsMap.putIfAbsent(mealId, () => []).add(rating);
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: meals.map((doc) {
                    final meal = doc.data() as Map<String, dynamic>;
                    final imageData = meal['image'];
                    Uint8List? imageBytes =
                        imageData != null && imageData is Uint8List
                        ? imageData
                        : null;
                    final mealId = doc.id;
                    final ratings = ratingsMap[mealId] ?? [];
                    final rating = ratings.isNotEmpty
                        ? ratings.reduce((a, b) => a + b) / ratings.length
                        : 0.0;

                    return foodCard(
                      context,
                      meal['meal_name'] as String,
                      imageBytes,
                      meal['price'].toString(),
                      rating.clamp(0.0, 5.0),
                      mealId,
                      const Color.fromARGB(255, 0, 0, 0),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
