import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../components/admin/masked_text.dart';

class AdminDeliversPage extends StatelessWidget {
  const AdminDeliversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.usersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
        final delivers = snap.data!.docs.where((d) {
          final roles = (d.data() as Map<String, dynamic>)['roles'] as Map? ?? {};
          return roles.containsKey('deliver');
        }).toList();

        if (delivers.isEmpty) {
          return Center(child: Text('No deliver agents found', style: TextStyle(color: Colors.white30)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: delivers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = delivers[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final deliver = data['roles']['deliver'] as Map<String, dynamic>? ?? {};
            final name = deliver['fullName']?.toString() ?? 'Unknown';
            final vehicle = deliver['vehicleType']?.toString() ?? '–';
            final isAvailable = deliver['isAvailable'] as bool? ?? false;
            final currentOrder = deliver['currentOrderId']?.toString() ?? '';
            final email = data['email']?.toString() ?? '';

            String status;
            Color statusColor;
            if (currentOrder.isNotEmpty) {
              status = 'ON DELIVERY';
              statusColor = const Color(0xFFFFC107);
            } else if (isAvailable) {
              status = 'AVAILABLE';
              statusColor = const Color(0xFF4CAF50);
            } else {
              status = 'OFFLINE';
              statusColor = Colors.white24;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111D35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF81D4FA), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(vehicle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 3),
                  MaskedText(value: email, type: MaskType.email, targetUid: uid,
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  if (currentOrder.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Order: $currentOrder', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ])),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  Switch(
                    value: isAvailable,
                    activeColor: const Color(0xFF29B6F6),
                    onChanged: (v) => AdminService.setDeliverAvailable(uid, v),
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}
