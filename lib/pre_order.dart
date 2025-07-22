import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/student_pre_orders.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/studentnotification_view.dart';

class PreOrder extends StatefulWidget {
  const PreOrder({super.key});

  @override
  State<PreOrder> createState() => _PreOrderState();
}

class _PreOrderState extends State<PreOrder> {
  String selectedCanteen = '';
  String selectedMealType = 'Breakfast';
  String selectedMeal = 'Select your meal';
  int quantity = 10; // Start quantity at 10
  List<String> canteens = [];
  List<Map<String, dynamic>> meals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCanteens();
  }

  Future<void> _fetchCanteens() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('canteens')
          .get();
      setState(() {
        canteens = snapshot.docs
            .map((doc) => doc['canteen_name'] as String)
            .toList();
        if (canteens.isNotEmpty) selectedCanteen = canteens[0];
        _fetchMeals();
      });
    } catch (e) {
      setState(() {
        canteens = ['Error loading canteens'];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching canteens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchMeals() async {
    if (selectedCanteen.isEmpty) {
      setState(() => meals = []);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('canteen_name', isEqualTo: selectedCanteen)
          .get();
      setState(() {
        meals = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['meal_name'] as String,
            'price': (data['price'] is int)
                ? data['price'] as int
                : (data['price'] is double)
                ? (data['price'] as double).toInt()
                : 0,
            'image': data['image'] as String?,
          };
        }).toList();
        isLoading = false;
        if (meals.isNotEmpty && !meals.any((m) => m['name'] == selectedMeal)) {
          selectedMeal = meals[0]['name'];
        }
      });
    } catch (e) {
      setState(() {
        meals = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching meals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        selectedMeal == 'Select your meal' ||
        selectedCanteen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a canteen and meal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('pre_orders').add({
        'user_id': user.uid,
        'canteen_name': selectedCanteen,
        'meal_type': selectedMealType,
        'meal_name': selectedMeal,
        'quantity': quantity,
        'total_price': _calculateTotal(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Pre-order request submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        selectedCanteen = canteens[0];
        selectedMealType = 'Breakfast';
        selectedMeal = 'Select your meal';
        quantity = 10; // Reset to 10
        _fetchMeals();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                            'Pre-Order your meal',
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown(
                            value: selectedCanteen,
                            items: canteens.isEmpty
                                ? ['No canteens available']
                                : canteens,
                            onChanged: (String? newValue) {
                              if (newValue != null &&
                                  newValue != 'No canteens available') {
                                setState(() {
                                  selectedCanteen = newValue;
                                  selectedMeal = 'Select your meal';
                                  _fetchMeals();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedMealType,
                            items: ['Breakfast', 'Lunch', 'Dinner'],
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMealType = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedMeal,
                            items: [
                              'Select your meal',
                              ...meals.map((m) => m['name'] as String),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMeal = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: meals.length,
                              itemBuilder: (context, index) {
                                final meal = meals[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildMealCard(meal),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (quantity > 10) {
                                            quantity--; // Prevent going below 10
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.remove),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          quantity++;
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _showOrderConfirmation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Request a Pre-Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentPreOrders(),
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
                                'View your Pre-Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty && items.isNotEmpty ? items[0] : value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.red),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMeal = meal['name'] as String;
        });
      },
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedMeal == meal['name']
                      ? Colors.red
                      : Colors.grey[400]!,
                  width: selectedMeal == meal['name'] ? 2 : 1,
                ),
              ),
              child: meal['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(meal['image']),
                    )
                  : _buildPlaceholderImage(meal['name'] as String),
            ),
            const SizedBox(height: 8),
            Text(
              meal['name'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selectedMeal == meal['name'] ? Colors.red : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${meal['price']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null) return _buildPlaceholderImage('');
    try {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage('');
        },
      );
    } catch (e) {
      return _buildPlaceholderImage('');
    }
  }

  Widget _buildPlaceholderImage(String mealName) {
    IconData icon;
    switch (mealName.toLowerCase()) {
      case 'veg maggie':
        icon = Icons.ramen_dining;
        break;
      case 'tea':
        icon = Icons.local_cafe;
        break;
      case 'poha':
        icon = Icons.rice_bowl;
        break;
      default:
        icon = Icons.fastfood;
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 32, color: Colors.grey[500]),
    );
  }

  void _showOrderConfirmation() {
    if (selectedMeal == 'Select your meal' || selectedCanteen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a canteen and meal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Order Confirmation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow('Canteen:', selectedCanteen),
              _buildConfirmationRow('Meal Type:', selectedMealType),
              _buildConfirmationRow('Selected Meal:', selectedMeal),
              _buildConfirmationRow('Quantity:', quantity.toString()),
              Divider(color: Colors.grey[300]),
              _buildConfirmationRow('Total Price:', 'Rs. ${_calculateTotal()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotal() {
    if (selectedMeal == 'Select your meal') return 0;
    final meal = meals.firstWhere(
      (m) => m['name'] == selectedMeal,
      orElse: () => {'price': 0},
    );
    return meal['price'] * quantity;
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CanteenApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
