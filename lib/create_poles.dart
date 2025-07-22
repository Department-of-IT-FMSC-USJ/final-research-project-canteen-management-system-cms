import 'package:flutter/material.dart';
import 'package:canteenapp/add_options.dart';
import 'package:canteenapp/manage_poles.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/canteen_notification_view.dart';

class CreatePoles extends StatefulWidget {
  const CreatePoles({super.key});

  @override
  State<CreatePoles> createState() => _CreatePolesState();
}

class _CreatePolesState extends State<CreatePoles> {
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Create Poles',
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
              child: ListView(
                children: [
                  _buildMealTimeButton('Breakfast', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddOptions(
                          canteenName: 'Open Canteen',
                          mealTime: 'Breakfast',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildMealTimeButton('Lunch', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddOptions(
                          canteenName: 'Open Canteen',
                          mealTime: 'Lunch',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildMealTimeButton('Dinner', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddOptions(
                          canteenName: 'Open Canteen',
                          mealTime: 'Dinner',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildManageButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManagePoles()),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color.fromARGB(255, 255, 0, 0),
            width: 2,
          ),
        ),
        child: const Center(
          child: Text(
            'Manage Polls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CanteenApp()),
      (route) => false,
    );
  }
}
