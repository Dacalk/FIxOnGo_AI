import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../components/admin/admin_confirm_dialog.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  String _tab = 'all';
  final _tabs = ['all', 'pending', 'accepted', 'arriving', 'completed', 'disputed', 'cancelled'];

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return const Color(0xFFFFC107);
      case 'accepted': case 'arriving': return const Color(0xFF4CAF50);
      case 'completed': return const Color(0xFF1A4DBE);
      case 'disputed': return const Color(0xFFEF5350);
      case 'cancelled': return Colors.white24;
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tab bar
      Container(
        height: 48,
        color: const Color(0xFF0D1626),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: _tabs.map((t) {
            final active = _tab == t;
            return GestureDetector(
              onTap: () => setState(() => _tab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1A4DBE) : const Color(0xFF111D35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? const Color(0xFF1A4DBE) : Colors.white12),
                ),
                child: Text(t[0].toUpperCase() + t.substring(1),
                    style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ),

      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: AdminService.requestsStream(status: _tab == 'all' ? null : _tab),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Text('No requests', style: TextStyle(color: Colors.white30)));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final rid = doc.id;
                final status = data['status']?.toString() ?? 'unknown';
                final userId = data['userId']?.toString() ?? '';
                final mechanicId = data['mechanicId']?.toString() ?? '';
                final desc = data['description']?.toString() ?? data['serviceType']?.toString() ?? '–';
                final ts = data['createdAt'] as Timestamp?;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111D35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 4, height: 60,
                      decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(desc, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status.toUpperCase(),
                              style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('User: ${userId.substring(0, userId.length.clamp(0, 8))}…  Mechanic: ${mechanicId.isEmpty ? "Unassigned" : mechanicId.substring(0, mechanicId.length.clamp(0, 8)) + "…"}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      if (ts != null)
                        Text(ts.toDate().toString().substring(0, 16), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                    ])),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                      color: const Color(0xFF1A2640),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (action) async {
                        if (action == 'cancel') {
                          final ok = await showAdminConfirmDialog(context,
                              title: 'Cancel Request',
                              message: 'Force-cancel this service request.',
                              confirmLabel: 'Cancel Request',
                              confirmColor: const Color(0xFFEF5350));
                          if (ok) await AdminService.cancelRequest(rid, 'Admin cancelled');
                        } else if (action == 'dispute') {
                          await AdminService.setRequestDisputed(rid, true);
                        } else if (action == 'resolve') {
                          await AdminService.setRequestDisputed(rid, false);
                        }
                      },
                      itemBuilder: (_) => [
                        if (status != 'cancelled')
                          const PopupMenuItem(value: 'cancel', child: Text('🚫 Force Cancel', style: TextStyle(color: Color(0xFFEF9A9A), fontSize: 13))),
                        if (status != 'disputed')
                          const PopupMenuItem(value: 'dispute', child: Text('⚠️ Mark Disputed', style: TextStyle(color: Colors.white70, fontSize: 13))),
                        if (status == 'disputed')
                          const PopupMenuItem(value: 'resolve', child: Text('✅ Mark Resolved', style: TextStyle(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
