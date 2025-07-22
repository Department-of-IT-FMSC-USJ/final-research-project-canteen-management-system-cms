import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/studentnotification_view.dart';

class ComplaintsAndSuggestions extends StatefulWidget {
  const ComplaintsAndSuggestions({super.key});

  @override
  State<ComplaintsAndSuggestions> createState() =>
      _ComplaintsAndSuggestionsState();
}

class _ComplaintsAndSuggestionsState extends State<ComplaintsAndSuggestions> {
  String? selectedCanteen;
  String? selectedComplaintType;
  final TextEditingController _ideaController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> canteenOptions = [];

  final List<String> complaintTypes = [
    'Food Quality',
    'Service Issues',
    'Cleanliness',
    'Pricing',
    'Staff Behavior',
    'Facilities',
    'Suggestion',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCanteens();
  }

  Future<void> _fetchCanteens() async {
    try {
      final snapshot = await _firestore.collection('canteens').get();
      setState(() {
        canteenOptions = snapshot.docs
            .map((doc) => doc['canteen_name'] as String)
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

  Future<bool> _checkUserExists(String uid) async {
    final studentDoc = await _firestore.collection('students').doc(uid).get();
    return studentDoc.exists;
  }

  Future<void> _submitComplaint() async {
    if (selectedCanteen == null ||
        selectedComplaintType == null ||
        _ideaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
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

      // Check if user exists in students collection
      final userExists = await _checkUserExists(user.uid);
      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not registered as a student. Contact admin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final complaintData = {
        'canteen_name': selectedCanteen,
        'complaint_type': selectedComplaintType,
        'message': _ideaController.text.trim(),
        'user_id': user.uid,
        'username': user.email ?? user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('complaints')
          .add(complaintData);

      if (_selectedImage != null) {
        final fileName = '${docRef.id}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('complaint_images')
            .child(fileName);

        await ref.putFile(_selectedImage!);
        final imageUrl = await ref.getDownloadURL();
        await docRef.update({'image_url': imageUrl});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      _ideaController.clear();
      setState(() {
        selectedCanteen = null;
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
    _ideaController.dispose();
    super.dispose();
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Canteen Dropdown
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
                      value: selectedCanteen,
                      items: canteenOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCanteen = newValue;
                        });
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Complaint Type Dropdown
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
                        'Complaint Type',
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

                  // Message Text Field
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _ideaController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'Type your complaint or suggestion...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Upload image section
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
}
