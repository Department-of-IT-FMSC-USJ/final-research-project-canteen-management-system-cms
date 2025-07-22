import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedRecipientType;
  String? _selectedCanteen;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> recipientTypes = [
    'specific_canteen',
    'all_canteens',
    'students',
    'both',
  ];

  List<String> canteenNames = [];

  @override
  void initState() {
    super.initState();
    _fetchCanteenNames();
  }

  Future<void> _fetchCanteenNames() async {
    try {
      final snapshot = await _firestore.collection('canteens').get();
      setState(() {
        canteenNames = snapshot.docs
            .map(
              (doc) =>
                  _capitalizeWords(doc['canteen_name'] as String? ?? 'Unknown'),
            )
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching canteens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Future<void> _submitNotification() async {
    if (_selectedRecipientType == null || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient type and enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in as admin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verify admin role
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      if (!adminDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can send notifications'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = {
        'message': _messageController.text.trim(),
        'recipient_type': _selectedRecipientType,
        'user_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_selectedRecipientType == 'specific_canteen' &&
          _selectedCanteen == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a specific canteen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedRecipientType == 'specific_canteen') {
        data['canteen_name'] = _selectedCanteen;
      }

      await _firestore.collection('notifications').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _messageController.clear();
      setState(() {
        _selectedRecipientType = null;
        _selectedCanteen = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
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
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Create Notifica...',
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
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CanteenApp(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text(
                        'Select Recipient Type',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      value: _selectedRecipientType,
                      items: recipientTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            _capitalizeWords(value.replaceAll('_', ' ')),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRecipientType = newValue;
                          _selectedCanteen = null; // Reset canteen selection
                        });
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  if (_selectedRecipientType == 'specific_canteen') ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        hint: const Text(
                          'Select Canteen',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        value: _selectedCanteen,
                        items: canteenNames.isEmpty
                            ? [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  enabled: false,
                                  child: Text('No canteens available'),
                                ),
                              ]
                            : canteenNames.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCanteen = newValue;
                          });
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'Type your notification here...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
