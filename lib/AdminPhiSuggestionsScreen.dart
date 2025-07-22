import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:canteenapp/main.dart';

class AdminPhiSuggestionsScreen extends StatefulWidget {
  const AdminPhiSuggestionsScreen({super.key});

  @override
  State<AdminPhiSuggestionsScreen> createState() =>
      _AdminPhiSuggestionsScreenState();
}

class _AdminPhiSuggestionsScreenState extends State<AdminPhiSuggestionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showError('Please log in to access this page');
        return;
      }

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      if (!adminDoc.exists) {
        _showError('Access denied. Admin privileges required.');
        return;
      }

      _loadSuggestions();
    } catch (e) {
      _showError('Error verifying admin access: $e');
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _firestore
          .collection('phi_suggestions')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> suggestions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        try {
          final phiDoc = await _firestore
              .collection('phi')
              .doc(data['user_id'])
              .get();
          if (phiDoc.exists) {
            data['phi_name'] = phiDoc.data()?['name'] ?? 'Unknown PHI';
            data['phi_email'] = phiDoc.data()?['email'] ?? 'No email';
          } else {
            data['phi_name'] = 'Unknown PHI';
            data['phi_email'] = 'No email';
          }
        } catch (e) {
          data['phi_name'] = 'Error loading name';
          data['phi_email'] = 'Error loading email';
        }

        suggestions.add(data);
      }

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading suggestions: $e';
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            )
          else if (_suggestions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No suggestions found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.red, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type: ${suggestion['suggestion_type'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Message: ${suggestion['message'] ?? 'No message'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Canteen: ${suggestion['canteen_name'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submitted by: ${suggestion['user_id'] ?? 'Unknown User ID'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${_formatTimestamp(suggestion['timestamp'])}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          if (suggestion['image_url'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  suggestion['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
