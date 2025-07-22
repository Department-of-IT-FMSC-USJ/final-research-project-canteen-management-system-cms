import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/add_meal_details.dart';
import 'dart:typed_data';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CanteenMealManagement extends StatefulWidget {
  const CanteenMealManagement({super.key});

  @override
  State<CanteenMealManagement> createState() => _CanteenMealManagementState();
}

class _CanteenMealManagementState extends State<CanteenMealManagement> {
  String? _canteenName;

  @override
  void initState() {
    super.initState();
    _fetchCanteenName();
  }

  Future<void> _fetchCanteenName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['canteen_name'] != null) {
        setState(() {
          _canteenName = userDoc.data()!['canteen_name'] as String;
        });
      } else {
        setState(() {
          _canteenName = user.uid;
        });
        print('Warning: canteen_name not found, using uid: ${user.uid}');
      }
    }
  }

  Future<void> _deleteMeal(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal deleted successfully!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting meal: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting meal: $e')));
    }
  }

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
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view meals'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
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

    if (_canteenName == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Builder(
        builder: (context) => Column(
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
                        'Menu Update',
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
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMealDetails(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add New Meal',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('meals')
                            .where('canteen_name', isEqualTo: _canteenName)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('StreamBuilder error: ${snapshot.error}');
                            return const Center(
                              child: Text('Error loading meals'),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No meals available'),
                            );
                          }

                          final meals = snapshot.data!.docs;
                          print('Fetched meals count: ${meals.length}');
                          return ListView.builder(
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final mealData = meals[index].data();
                              if (mealData == null) {
                                print('Null meal data at index $index');
                                return const SizedBox.shrink();
                              }
                              final meal = mealData is Map<String, dynamic>
                                  ? mealData
                                  : <String, dynamic>{};
                              if (meal.isEmpty) {
                                print(
                                  'Empty or invalid meal data at index $index',
                                );
                                return const SizedBox.shrink();
                              }
                              final docId = meals[index].id;
                              final imageData = meal['image'];
                              print(
                                'Image data type at index $index: ${imageData?.runtimeType}',
                              );

                              Uint8List? imageBytes;
                              if (imageData != null) {
                                if (imageData is Uint8List) {
                                  imageBytes = imageData;
                                } else {
                                  print(
                                    'Unexpected image type at index $index: $imageData',
                                  );
                                  imageBytes = null;
                                }
                              }

                              final items =
                                  meal['items'] as List<dynamic>? ?? [];
                              final itemsWidgets = items.isNotEmpty
                                  ? items
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Text(
                                              item.toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()
                                  : [
                                      const Text(
                                        'No items',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ];

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: imageBytes != null
                                      ? Image.memory(
                                          imageBytes,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print(
                                                  'Image error at index $index: $error',
                                                );
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                );
                                              },
                                        )
                                      : const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                        ),
                                  title: Text(
                                    meal['meal_name'] ?? 'Unnamed Meal',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rs. ${meal['price']?.toString() ?? '0'}',
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4.0,
                                        runSpacing: 4.0,
                                        children: itemsWidgets,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddMealDetails(
                                                    mealId: docId,
                                                    initialMealName:
                                                        meal['meal_name']
                                                            as String?,
                                                    initialPrice: meal['price']
                                                        ?.toString(),
                                                    initialItems:
                                                        List<String>.from(
                                                          meal['items'] ?? [],
                                                        ),
                                                    initialImage: imageBytes,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Confirm Delete',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this meal?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _deleteMeal(docId);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
