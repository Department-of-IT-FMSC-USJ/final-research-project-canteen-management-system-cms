import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class AddItemsOnOptions extends StatefulWidget {
  final String canteenName;
  final String mealTime;
  final String optionNumber;
  final bool isEditing;
  final List<String>? existingItems;
  final String? pollId;

  const AddItemsOnOptions({
    super.key,
    required this.canteenName,
    required this.mealTime,
    required this.optionNumber,
    this.isEditing = false,
    this.existingItems,
    this.pollId,
  });

  @override
  State<AddItemsOnOptions> createState() => _AddItemsOnOptionsState();
}

class _AddItemsOnOptionsState extends State<AddItemsOnOptions> {
  List<TextEditingController> itemControllers = [];
  List<Widget> itemFields = [];
  int itemCount = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingItems != null) {
      _loadExistingItems();
    } else {
      _addInitialItems();
    }
  }

  void _loadExistingItems() {
    for (String item in widget.existingItems!) {
      TextEditingController controller = TextEditingController(text: item);
      itemControllers.add(controller);
    }
    _rebuildItemFields();
  }

  void _addInitialItems() {
    for (int i = 0; i < 3; i++) {
      _addItemField();
    }
  }

  void _addItemField() {
    TextEditingController controller = TextEditingController();
    itemControllers.add(controller);

    Widget itemField = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              '${itemControllers.length}.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter item name',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                int index = itemControllers.indexOf(controller);
                itemControllers.removeAt(index);
                _rebuildItemFields();
              });
            },
          ),
        ],
      ),
    );

    setState(() {
      itemFields.add(itemField);
    });
  }

  void _rebuildItemFields() {
    itemFields.clear();
    for (int i = 0; i < itemControllers.length; i++) {
      Widget itemField = Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Text(
                '${i + 1}.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: itemControllers[i],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter item name',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  itemControllers.removeAt(i);
                  _rebuildItemFields();
                });
              },
            ),
          ],
        ),
      );
      itemFields.add(itemField);
    }
  }

  Future<void> _saveToFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
        return;
      }

      List<String> items = itemControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      if (widget.isEditing && widget.pollId != null) {
        await FirebaseFirestore.instance
            .collection('polls')
            .doc(widget.pollId)
            .update({
              'items': items,
              'updated_at': FieldValue.serverTimestamp(),
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll data updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        String docId =
            '${widget.canteenName}_${widget.mealTime}_${widget.optionNumber}'
                .toLowerCase()
                .replaceAll(' ', '_');
        await FirebaseFirestore.instance.collection('polls').doc(docId).set({
          'canteen_name': widget.canteenName,
          'meal_time': widget.mealTime,
          'option_number': widget.optionNumber,
          'items': items,
          'created_by': user.uid,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'votes': 0,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll data saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      Navigator.pop(context);
      if (!widget.isEditing) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving poll data: $e')));
    }
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Create Poll',
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
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.mealTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'Add ${widget.optionNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        ...itemFields,
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _addItemField,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Add More Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _saveToFirestore,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                widget.isEditing
                                    ? 'Update Poll Data'
                                    : 'Save Poll Data',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    for (var controller in itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
