import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';
import 'add_card_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String role;

  const PaymentScreen({super.key, required this.role});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;
  String? selectedCardId;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

// 🔥 LOAD CARDS (NEW PATH)
  Future<void> loadCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('role') // 🔥 changed
        .doc(widget.role)
        .collection('cards')
        .get();

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

// 🔥 DELETE CARD (NEW PATH)
  Future<void> deleteCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('role') // 🔥 changed
        .doc(widget.role)
        .collection('cards')
        .doc(cardId)
        .delete();

    loadCards();
  }

// 🔥 MIGRATION FUNCTION (OLD → NEW)
  Future<void> migrateCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final oldCards = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cards')
        .get();

    for (var doc in oldCards.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('role') // 🔥 changed
          .doc(widget.role)
          .collection('cards')
          .doc(doc.id)
          .set(doc.data());
    }

    print("Migration Done");
    loadCards();
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
          'Payment Methods (${widget.role})',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),

      // 🔥 BODY
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

      // 🔥 BUTTONS
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 MIGRATION BUTTON (TEMP)
          FloatingActionButton(
            heroTag: "migrate",
            backgroundColor: Colors.orange,
            onPressed: migrateCards,
            child: const Icon(Icons.sync),
          ),

          const SizedBox(height: 10),

          // 🔥 ADD CARD
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardScreen(role: widget.role),
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
