import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CanteenComplaintScreen extends StatefulWidget {
  const CanteenComplaintScreen({super.key});

  @override
  State<CanteenComplaintScreen> createState() => _CanteenComplaintScreenState();
}

class _CanteenComplaintScreenState extends State<CanteenComplaintScreen> {
  String? selectedComplaintType;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> complaintTypes = [
    'Supply Shortages',
    'Staff Shortages',
    'Equipment Failure',
    'Maintenance Issues',
    'Payment Delays',
    'Regulatory Compliance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('complaint_images')
          .child(
            '${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser!.uid}.jpg',
          );
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    if (selectedComplaintType == null || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a complaint type and enter a message'),
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
            content: Text('Please log in to submit a complaint'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final canteenDoc = await _firestore
          .collection('canteens')
          .doc(user.uid)
          .get();
      if (!canteenDoc.exists || canteenDoc.data()?['role'] != 'canteen') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only canteens can submit complaints'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final canteenName = canteenDoc.data()?['canteen_name'] as String? ?? '';
      if (canteenName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canteen name not found. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare complaint data
      final complaintData = {
        'canteen_name': canteenName,
        'complaint_type': selectedComplaintType,
        'message': _messageController.text.trim(),
        'user_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      if (_selectedImage != null) {
        final imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl != null) {
          complaintData['image_url'] = imageUrl;
        }
      }

      await _firestore.collection('complaints').add(complaintData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
      _messageController.clear();
      setState(() {
        selectedComplaintType = null;
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.red),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.red),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
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
                        'Complaints & Sugg..',
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        'Select Issue Type',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      value: selectedComplaintType,
                      items: complaintTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedComplaintType = newValue;
                        });
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.red,
                      ),
                    ),
                  ),
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
                        hintText: 'Type your issue here...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          _showUploadOptions(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.upload,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    Image.file(_selectedImage!, height: 100, width: 100),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Submit',
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

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
