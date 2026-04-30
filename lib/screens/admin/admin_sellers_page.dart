import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../components/admin/masked_text.dart';

class AdminSellersPage extends StatelessWidget {
  const AdminSellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.usersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
        final sellers = snap.data!.docs.where((d) {
          final roles = (d.data() as Map<String, dynamic>)['roles'] as Map? ?? {};
          return roles.containsKey('seller');
        }).toList();

        if (sellers.isEmpty) {
          return Center(child: Text('No sellers found', style: TextStyle(color: Colors.white30)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sellers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = sellers[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final seller = data['roles']['seller'] as Map<String, dynamic>? ?? {};
            final shopName = seller['shopName']?.toString() ?? 'Unknown Shop';
            final isActive = seller['isActive'] as bool? ?? false;
            final isApproved = seller['isApproved'] as bool? ?? false;
            final email = data['email']?.toString() ?? '';

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
                    color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded, color: Color(0xFFFFD54F), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shopName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  MaskedText(value: email, type: MaskType.email, targetUid: uid,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _Chip(isApproved ? 'Approved' : 'Pending Approval',
                        isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFFC107)),
                    const SizedBox(width: 8),
                    _Chip(isActive ? 'Active' : 'Inactive',
                        isActive ? const Color(0xFF29B6F6) : Colors.white24),
                  ]),
                ])),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!isApproved)
                    TextButton(
                      onPressed: () => AdminService.approveSellerApplication(uid),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF81C784),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 12)),
                    ),
                  Switch(
                    value: isActive,
                    activeColor: const Color(0xFFFFC107),
                    onChanged: (v) => AdminService.setSellerActive(uid, v),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
