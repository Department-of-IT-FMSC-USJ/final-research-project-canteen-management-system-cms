import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/studentnotification_view.dart';
import 'package:canteenapp/main.dart';

class StudentPreOrders extends StatefulWidget {
  const StudentPreOrders({super.key});

  @override
  State<StudentPreOrders> createState() => _StudentPreOrdersState();
}

class _StudentPreOrdersState extends State<StudentPreOrders> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
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
                        'My Pre-Orders',
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pre_orders')
                    .where('user_id', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Error loading pre-orders: ${snapshot.error}');
                    return const Center(
                      child: Text('Error loading pre-orders'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No pre-orders found'));
                  }

                  final preOrders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: preOrders.length,
                    itemBuilder: (context, index) {
                      final preOrder =
                          preOrders[index].data() as Map<String, dynamic>;
                      final preOrderId = preOrders[index].id;
                      final status = preOrder['status'] ?? 'pending';
                      final timestamp = preOrder['timestamp'] is Timestamp
                          ? (preOrder['timestamp'] as Timestamp).toDate()
                          : null;

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
                          title: Text(
                            preOrder['meal_name'] ?? 'Unnamed Meal',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Canteen: ${preOrder['canteen_name'] ?? 'Unknown'}',
                              ),
                              Text(
                                'Type: ${preOrder['meal_type'] ?? 'Unknown'}',
                              ),
                              Text('Quantity: ${preOrder['quantity'] ?? 0}'),
                              Text(
                                'Total: Rs. ${preOrder['total_price'] ?? 0}',
                              ),
                              Text('Status: $status'),
                              if (timestamp != null)
                                Text(
                                  'Ordered: ${timestamp.toLocal().toString().split('.')[0]}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (status == 'ready')
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('pre_orders')
                                          .doc(preOrderId)
                                          .update({'status': 'completed'});
                                      await FirebaseFirestore.instance
                                          .collection('pre_orders')
                                          .doc(preOrderId)
                                          .delete();
                                      _scaffoldMessengerKey.currentState
                                          ?.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Order collected and removed!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                    } catch (e) {
                                      _scaffoldMessengerKey.currentState
                                          ?.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to collect order: $e. Contact support.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Order Collected',
                                    style: TextStyle(color: Colors.white),
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
          ],
        ),
      ),
    );
  }
}
