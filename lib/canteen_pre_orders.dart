import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CanteenPreOrders extends StatefulWidget {
  const CanteenPreOrders({super.key});

  @override
  State<CanteenPreOrders> createState() => _CanteenPreOrdersState();
}

class _CanteenPreOrdersState extends State<CanteenPreOrders> {
  String? _canteenName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCanteenName();
  }

  Future<void> _fetchCanteenName() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('canteens')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data()?['canteen_name'] != null) {
          setState(() {
            _canteenName = userDoc.data()?['canteen_name'] as String;
            print('Fetched canteen name: $_canteenName');
            _isLoading = false;
          });
        } else {
          setState(() {
            _canteenName = null;
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Canteen name not found in document. Contact support.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching canteen name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String preOrderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pre_orders')
          .doc(preOrderId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $newStatus!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e. Contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CanteenApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_canteenName == null) {
      return const Scaffold(
        body: Center(
          child: Text('Canteen not found. Please log in as a canteen user.'),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Manage Pre-Orders',
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
                  .collection('pre_orders')
                  .where('canteen_name', isEqualTo: _canteenName)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error loading pre-orders: ${snapshot.error}');
                  return Center(
                    child: Text('Error loading pre-orders: ${snapshot.error}'),
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
                              'Student ID: ${preOrder['user_id'] ?? 'Unknown'}',
                            ),
                            Text('Type: ${preOrder['meal_type'] ?? 'Unknown'}'),
                            Text('Quantity: ${preOrder['quantity'] ?? 0}'),
                            Text('Total: Rs. ${preOrder['total_price'] ?? 0}'),
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
                            if (status == 'pending')
                              ElevatedButton(
                                onPressed: () =>
                                    _updateStatus(preOrderId, 'ready'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Mark as Ready',
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
    );
  }
}
