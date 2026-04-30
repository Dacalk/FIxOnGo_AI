import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../components/admin/masked_text.dart';

class AdminMechanicsPage extends StatelessWidget {
  const AdminMechanicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.usersStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
        final mechanics = snap.data!.docs.where((d) {
          final roles = (d.data() as Map<String, dynamic>)['roles'] as Map? ?? {};
          return roles.containsKey('mechanic');
        }).toList();

        if (mechanics.isEmpty) {
          return Center(child: Text('No mechanics found', style: TextStyle(color: Colors.white30)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: mechanics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = mechanics[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final mechanic = data['roles']['mechanic'] as Map<String, dynamic>? ?? {};
            final name = mechanic['fullName']?.toString() ?? 'Unknown';
            final workshop = mechanic['workshop']?.toString() ?? '–';
            final isActive = mechanic['isActive'] as bool? ?? false;
            final email = data['email']?.toString() ?? '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111D35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(children: [
                // Status dot
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF4CAF50) : Colors.white24,
                    boxShadow: isActive ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 6)] : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(workshop, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 3),
                  MaskedText(value: email, type: MaskType.email, targetUid: uid,
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ])),
                Column(children: [
                  Text(isActive ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                          color: isActive ? const Color(0xFF81C784) : Colors.white38,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Switch(
                    value: isActive,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (v) => AdminService.setMechanicActive(uid, v),
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
