import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class AddMealDetails extends StatefulWidget {
  final String? mealId;
  final String? initialMealName;
  final String? initialPrice;
  final List<String>? initialItems;
  final Uint8List? initialImage;

  const AddMealDetails({
    super.key,
    this.mealId,
    this.initialMealName,
    this.initialPrice,
    this.initialItems,
    this.initialImage,
  });

  @override
  State<AddMealDetails> createState() => _AddMealDetailsState();
}

class _AddMealDetailsState extends State<AddMealDetails> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _priceController = TextEditingController();
  final List<TextEditingController> _itemControllers = [];
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (widget.initialMealName != null) {
      _mealNameController.text = widget.initialMealName!;
    }
    if (widget.initialPrice != null) {
      _priceController.text = widget.initialPrice!;
    }
    if (widget.initialItems != null) {
      for (String item in widget.initialItems!) {
        _itemControllers.add(TextEditingController(text: item));
      }
    } else {
      _itemControllers.add(TextEditingController());
    }
    _imageBytes = widget.initialImage;
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Image Source',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.red),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.red),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveToFirestore() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String canteenName = user.uid; // Default to UID if no canteen_name
      final userDoc = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['canteen_name'] != null) {
        canteenName = userDoc.data()!['canteen_name'] as String;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canteen name not found. Contact admin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      List<String> items = _itemControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String docId =
          widget.mealId ?? '${canteenName}_${_mealNameController.text.trim()}';
      double price;
      try {
        price = double.parse(_priceController.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final mealData = {
        'canteen_name': canteenName,
        'meal_name': _mealNameController.text.trim(),
        'items': items,
        'price': price,
        'created_by': user.uid,
        'created_at': widget.mealId == null
            ? FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
      };
      if (_imageBytes != null) {
        mealData['image'] = Uint8List.fromList(_imageBytes!);
      }

      final mealRef = FirebaseFirestore.instance.collection('meals').doc(docId);
      await mealRef.set(mealData, SetOptions(merge: widget.mealId != null));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal saved successfully!'),
          backgroundColor: Colors.green, // Changed to green
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('Error saving meal: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
    });
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
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _mealNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      Text(
                        widget.mealId == null
                            ? 'Add Meal Details'
                            : 'Edit Meal Details',
                        style: const TextStyle(
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
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mealNameController,
                        decoration: const InputDecoration(
                          labelText: 'Meal Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter meal name' : null,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : const Center(
                                  child: Text('Tap to add photo (optional)'),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (Rs.)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter price' : null,
                      ),
                      const SizedBox(height: 16),
                      ..._itemControllers.map(
                        (controller) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Item',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter an item' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addItemField,
                        child: const Text('Add More Items'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveToFirestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
