import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

class AdminAuditPage extends StatelessWidget {
  const AdminAuditPage({super.key});

  Color _actionColor(String action) {
    if (action.contains('ban') || action.contains('delete') || action.contains('revoke')) {
      return const Color(0xFFEF5350);
    }
    if (action.contains('grant') || action.contains('approve')) return const Color(0xFF4CAF50);
    if (action.contains('reveal')) return const Color(0xFFFFC107);
    if (action.contains('settings')) return const Color(0xFF29B6F6);
    return const Color(0xFF90CAF9);
  }

  IconData _actionIcon(String action) {
    if (action.contains('ban')) return Icons.block_rounded;
    if (action.contains('delete')) return Icons.delete_rounded;
    if (action.contains('grant') || action.contains('approve')) return Icons.verified_rounded;
    if (action.contains('revoke')) return Icons.remove_circle_rounded;
    if (action.contains('reveal')) return Icons.visibility_rounded;
    if (action.contains('settings')) return Icons.settings_rounded;
    if (action.contains('cancel')) return Icons.cancel_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AdminService.auditLogsStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.history_toggle_off, color: Colors.white12, size: 64),
            const SizedBox(height: 12),
            Text('No audit entries yet', style: TextStyle(color: Colors.white30)),
          ]));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final action = data['action']?.toString() ?? 'unknown';
            final adminEmail = data['adminEmail']?.toString() ?? '–';
            final targetId = data['targetId']?.toString() ?? '';
            final ts = data['timestamp'] as Timestamp?;
            final details = data['details'] as Map<String, dynamic>? ?? {};
            final color = _actionColor(action);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111D35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_actionIcon(action), color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(action.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text('By: $adminEmail', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  if (targetId.isNotEmpty)
                    Text('Target: ${targetId.length > 16 ? targetId.substring(0, 16) + "…" : targetId}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  if (details.isNotEmpty)
                    Text(details.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                ])),
                if (ts != null)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(ts.toDate().toString().substring(0, 10),
                        style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    Text(ts.toDate().toString().substring(11, 16),
                        style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ]),
              ]),
            );
          },
        );
      },
    );
  }
}
