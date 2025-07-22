import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:canteenapp/main.dart';

class PhiSuggestionScreen extends StatefulWidget {
  const PhiSuggestionScreen({super.key});

  @override
  State<PhiSuggestionScreen> createState() => _PhiSuggestionScreenState();
}

class _PhiSuggestionScreenState extends State<PhiSuggestionScreen> {
  String? _selectedCanteen;
  final TextEditingController _suggestionTypeController =
      TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<String> canteenNames = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCanteenNames();
  }

  Future<void> _fetchCanteenNames() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final snapshot = await _firestore.collection('canteens').get();
      setState(() {
        canteenNames = snapshot.docs
            .map((doc) => doc.data()['canteen_name'] as String? ?? 'Unknown')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load canteen names: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = firebase_storage.FirebaseStorage.instance.ref().child(
        'phi_suggestions/${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser!.uid}.jpg',
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

  Future<void> _submitSuggestion() async {
    if (_selectedCanteen == null ||
        _suggestionTypeController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to submit a suggestion'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Authenticated UID: ${user.uid}');

      // Check PHI document
      final phiDoc = await _firestore.collection('phi').doc(user.uid).get();
      print('PHI Document Exists: ${phiDoc.exists}');
      if (!phiDoc.exists) {
        print('PHI document does not exist for UID: ${user.uid}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PHI profile not found. Contact admin to set up your role.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final phiData = phiDoc.data();
      print('PHI Document Data: $phiData');
      if (phiData?['role'] != 'phi') {
        print('User role is not "phi". Current role: ${phiData?['role']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only PHI users can submit suggestions'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verify canteen_name exists in canteens collection
      final canteenQuery = await _firestore
          .collection('canteens')
          .where('canteen_name', isEqualTo: _selectedCanteen)
          .get();
      if (canteenQuery.docs.isEmpty) {
        print('Canteen not found: $_selectedCanteen');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Canteen "$_selectedCanteen" not found in database'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('Canteen found: $_selectedCanteen');

      // Upload image first if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          print('Image upload failed');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final suggestionData = {
        'canteen_name': _selectedCanteen!,
        'suggestion_type': _suggestionTypeController.text.trim(),
        'message': _messageController.text.trim(),
        'user_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'image_url': imageUrl, // This will be null if no image was uploaded
      };

      print('Submitting data: $suggestionData');

      // Attempt to write to Firestore
      await _firestore.collection('phi_suggestions').add(suggestionData);
      print('Suggestion successfully written to Firestore');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suggestion submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedCanteen = null;
        _suggestionTypeController.clear();
        _messageController.clear();
        _selectedImage = null;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error submitting suggestion: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error submitting suggestion: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting suggestion: $e'),
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
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                            'PHI Suggestions',
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
                                  builder: (context) => const LoginPage(),
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
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
                          items: canteenNames.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (String? newValue) {
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
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _suggestionTypeController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintText: 'Enter Suggestion Type...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          enabled: !_isLoading,
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
                            hintText: 'Type your suggestion here...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Text(
                            'Upload Photo (Optional)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => _showUploadOptions(context),
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
                            onPressed: _isLoading ? null : _submitSuggestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _suggestionTypeController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
