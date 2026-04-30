import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.paymentsStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
        final docs = snap.data!.docs;

        num total = 0, today = 0;
        final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          num amount = 0;
          final amtRaw = data['amount'];
          if (amtRaw is num) {
            amount = amtRaw;
          } else if (amtRaw is String) {
            final cleanStr = amtRaw.replaceAll(RegExp(r'[^0-9.]'), '');
            amount = num.tryParse(cleanStr) ?? 0;
          }
          total += amount;
          final ts = data['createdAt'] as Timestamp?;
          if (ts != null && ts.toDate().isAfter(todayStart)) today += amount;
        }

        return Column(children: [
          // Revenue summary
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D1626),
            child: Row(children: [
              _RevCard('Total Transactions', docs.length.toString(), Icons.receipt_long_rounded, const Color(0xFF1A4DBE)),
              const SizedBox(width: 12),
              _RevCard("Today's Revenue", 'LKR ${today.toStringAsFixed(0)}', Icons.today_rounded, const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _RevCard('All-time Revenue', 'LKR ${total.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFFFFC107)),
            ]),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0B1120),
            child: Row(children: const [
              Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
              Expanded(flex: 3, child: Text('USER', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
              Expanded(flex: 2, child: Text('MECHANIC', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
              Expanded(flex: 1, child: Text('AMOUNT', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
              Expanded(flex: 1, child: Text('STATUS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ]),
          ),

          // Payment rows
          Expanded(
            child: docs.isEmpty
                ? Center(child: Text('No payments yet', style: TextStyle(color: Colors.white30)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final ts = data['createdAt'] as Timestamp?;
                      final date = ts != null ? ts.toDate().toString().substring(0, 16) : '–';
                      final userName = data['userName']?.toString() ?? '–';
                      final mechanicName = data['mechanicName']?.toString() ?? '–';
                      String amountStr = '0';
                      final amtRaw2 = data['amount'];
                      if (amtRaw2 is num) {
                        amountStr = amtRaw2.toString();
                      } else if (amtRaw2 is String) {
                        final cleanStr = amtRaw2.replaceAll(RegExp(r'[^0-9.]'), '');
                        amountStr = (num.tryParse(cleanStr) ?? 0).toString();
                      }
                      final currency = data['currency']?.toString() ?? 'LKR';
                      final status = data['status']?.toString() ?? 'unknown';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12))),
                          Expanded(flex: 3, child: Text(userName, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 2, child: Text(mechanicName, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 1, child: Text('$currency $amountStr', style: const TextStyle(color: Color(0xFF81C784), fontSize: 12, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'success'
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                  : const Color(0xFFEF5350).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    color: status == 'success' ? const Color(0xFF81C784) : const Color(0xFFEF9A9A),
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          )),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}

class _RevCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _RevCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ])),
        ]),
      ),
    );
  }
}
