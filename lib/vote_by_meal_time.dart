import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:canteenapp/main.dart';
import 'package:canteenapp/studentnotification_view.dart';

class VoteByMealTime extends StatefulWidget {
  final String canteenName;

  const VoteByMealTime({super.key, required this.canteenName});

  @override
  State<VoteByMealTime> createState() => _VoteByMealTimeState();
}

class _VoteByMealTimeState extends State<VoteByMealTime> {
  int? selectedBreakfastOption;
  int? selectedLunchOption;
  int? selectedDinnerOption;

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
                      'Vote your Prefere...',
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Available Polls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('polls')
                        .where('canteen_name', isEqualTo: widget.canteenName)
                        .orderBy('meal_time')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Stream error: ${snapshot.error}');
                        return Center(
                          child: Text('Error loading polls: ${snapshot.error}'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No polls available'));
                      }

                      // Group data by meal time
                      final polesData = <String, List<Map<String, dynamic>>>{};
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final mealTime = data['meal_time'] as String;
                        polesData.putIfAbsent(mealTime, () => []).add({
                          'option_number': data['option_number'],
                          'items': List<String>.from(data['items'] ?? []),
                          'docId': doc.id,
                          'votes': data['votes'] ?? 0,
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (polesData.containsKey('Breakfast'))
                            _buildMealTimeSection(
                              'Breakfast',
                              polesData['Breakfast']!,
                            ),
                          const SizedBox(height: 30),
                          if (polesData.containsKey('Lunch'))
                            _buildMealTimeSection('Lunch', polesData['Lunch']!),
                          const SizedBox(height: 30),
                          if (polesData.containsKey('Dinner'))
                            _buildMealTimeSection(
                              'Dinner',
                              polesData['Dinner']!,
                            ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeSection(
    String mealTime,
    List<Map<String, dynamic>> options,
  ) {
    int? selectedOption = mealTime == 'Breakfast'
        ? selectedBreakfastOption
        : mealTime == 'Lunch'
        ? selectedLunchOption
        : selectedDinnerOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Center(
            child: Text(
              mealTime,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children:
              options
                  .asMap()
                  .entries
                  .map((entry) {
                    int index = entry.key;
                    final option = entry.value;
                    return Expanded(
                      child: _buildOptionCard(
                        option['option_number'] as String,
                        index,
                        selectedOption,
                        (idx) => setState(() {
                          if (mealTime == 'Breakfast') {
                            selectedBreakfastOption = idx;
                          }
                          if (mealTime == 'Lunch') selectedLunchOption = idx;
                          if (mealTime == 'Dinner') selectedDinnerOption = idx;
                          _showVoteConfirmation(mealTime, idx, option);
                        }),
                        option['items'] as List<String>,
                        option['votes'] as int,
                      ),
                    );
                  })
                  .toList()
                  .expand((widget) => [widget, const SizedBox(width: 10)])
                  .toList()
                ..removeLast(),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    String optionTitle,
    int optionIndex,
    int? selectedOption,
    Function(int) onOptionSelected,
    List<String> items,
    int votes,
  ) {
    bool isSelected = selectedOption == optionIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 35,
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                optionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              height: 35,
              child: ElevatedButton(
                onPressed: () => onOptionSelected(optionIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Vote ($votes)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoteConfirmation(
    String mealTime,
    int optionIndex,
    Map<String, dynamic> option,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vote Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meal Time: $mealTime'),
              Text('Option: ${option['option_number']}'),
              const SizedBox(height: 10),
              const Text('Items:'),
              ...(option['items'] as List<String>).map(
                (item) => Text('• $item'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () =>
                  _submitVote(mealTime, optionIndex, option['docId']),
              child: const Text('Vote', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitVote(
    String mealTime,
    int optionIndex,
    String docId,
  ) async {
    Navigator.pop(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to vote')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('polls').doc(docId).update({
        'votes': FieldValue.increment(1),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Clear selection and stay on the same screen
      setState(() {
        if (mealTime == 'Breakfast') selectedBreakfastOption = null;
        if (mealTime == 'Lunch') selectedLunchOption = null;
        if (mealTime == 'Dinner') selectedDinnerOption = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error voting: $e')));
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CanteenApp()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
    }
  }
}
