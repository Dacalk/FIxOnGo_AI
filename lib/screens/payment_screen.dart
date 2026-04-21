import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';
import 'add_card_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? role;

  const PaymentScreen({super.key, this.role});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;
  String? selectedCardId;
  String? _effectiveRole;

  @override
  void initState() {
    super.initState();
    _effectiveRole = widget.role;
    _initPaymentData();
  }

  Future<void> _initPaymentData() async {
    if (_effectiveRole == null) {
      await _fetchUserRole();
    }
    if (_effectiveRole != null) {
      loadCards();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final roles = doc.data()?['roles'] as Map<String, dynamic>? ?? {};
          if (roles.isNotEmpty) {
            _effectiveRole = roles.keys.first;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching role in PaymentScreen: $e");
    }
  }

  Future<void> loadCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _effectiveRole == null) return;

    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('role')
          .doc(_effectiveRole)
          .collection('cards')
          .get();

      if (mounted) {
        setState(() {
          cards = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading cards: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _effectiveRole == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('role')
          .doc(_effectiveRole)
          .collection('cards')
          .doc(cardId)
          .delete();

      loadCards();
    } catch (e) {
      debugPrint("Error deleting card: $e");
    }
  }

  Future<void> migrateCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _effectiveRole == null) return;

    try {
      final oldCards = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      for (var doc in oldCards.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('role')
            .doc(_effectiveRole)
            .collection('cards')
            .doc(doc.id)
            .set(doc.data());
      }

      debugPrint("Migration Done");
      loadCards();
    } catch (e) {
      debugPrint("Error during migration: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : const Color(0xFFF4F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Payment Methods (${_effectiveRole ?? "..."})',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? const Center(child: Text("No Cards Found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card, size: 28),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['cardHolder'] ?? 'Card',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['cardNumber'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Card"),
                                  content: const Text("Are you sure?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                deleteCard(card['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "migrate",
            backgroundColor: Colors.orange,
            onPressed: migrateCards,
            child: const Icon(Icons.sync),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardScreen(role: _effectiveRole),
                ),
              );
              loadCards();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
