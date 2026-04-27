import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../components/admin/masked_text.dart';
import '../../components/admin/role_badge.dart';
import '../../components/admin/admin_confirm_dialog.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'all';
  final _filters = ['all', 'user', 'mechanic', 'seller', 'deliver', 'admin', 'banned'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<QueryDocumentSnapshot> _apply(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final roles = data['roles'] as Map<String, dynamic>? ?? {};
      final email = (data['email'] ?? '').toString().toLowerCase();
      final banned = data['isBanned'] == true;
      if (_search.isNotEmpty && !email.contains(_search.toLowerCase())) {
        final names = roles.values.whereType<Map>()
            .map((r) => (r['fullName'] ?? '').toString().toLowerCase()).join(' ');
        if (!names.contains(_search.toLowerCase())) return false;
      }
      if (_filter == 'all') return true;
      if (_filter == 'banned') return banned;
      return roles.containsKey(_filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0B1120),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by email or name…',
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _filters.map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1)),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: const Color(0xFF1A4DBE).withValues(alpha: 0.3),
                    checkmarkColor: const Color(0xFF90CAF9),
                    backgroundColor: const Color(0xFF111D35),
                    labelStyle: TextStyle(color: active ? const Color(0xFF90CAF9) : Colors.white54, fontSize: 12),
                    side: BorderSide(color: active ? const Color(0xFF1A4DBE) : Colors.white12),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AdminService.usersStream(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));
              final filtered = _apply(snap.data!.docs);
              if (filtered.isEmpty) return Center(child: Text('No users found', style: TextStyle(color: Colors.white30)));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserTile(doc: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _UserTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final roles = data['roles'] as Map<String, dynamic>? ?? {};
    final banned = data['isBanned'] == true;
    final photoUrl = data['photoUrl']?.toString() ?? '';
    String name = '';
    for (final r in roles.values) {
      if (r is Map && (r['fullName'] ?? '').toString().isNotEmpty) { name = r['fullName']; break; }
    }
    if (name.isEmpty) name = email.split('@').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111D35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: banned
            ? const Color(0xFFEF5350).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1A4DBE).withValues(alpha: 0.3),
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? Text(name[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF90CAF9), fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            if (banned) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEF5350).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('BANNED', style: TextStyle(color: Color(0xFFEF9A9A), fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ]),
          const SizedBox(height: 4),
          MaskedText(value: email, type: MaskType.email, targetUid: uid,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            MaskedText(value: phone, type: MaskType.phone, targetUid: uid,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: roles.keys.map((r) => RoleBadge(r)).toList()),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
          color: const Color(0xFF1A2640),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) async {
            if (action == 'ban') {
              final ok = await showAdminConfirmDialog(context,
                  title: banned ? 'Unban User' : 'Ban User',
                  message: banned ? 'Restore access to this user.' : 'Prevent this user from using the app.',
                  confirmLabel: banned ? 'Unban' : 'Ban',
                  confirmColor: banned ? const Color(0xFF4CAF50) : const Color(0xFFEF5350));
              if (ok) await AdminService.setBanStatus(uid, !banned);
            } else if (action == 'admin') {
              final hasAdmin = roles.containsKey('admin');
              final ok = await showAdminConfirmDialog(context,
                  title: hasAdmin ? 'Revoke Admin' : 'Grant Admin',
                  message: hasAdmin ? 'Remove admin access.' : 'Grant full admin access.',
                  confirmLabel: hasAdmin ? 'Revoke' : 'Grant',
                  confirmColor: hasAdmin ? const Color(0xFFEF5350) : const Color(0xFF1A4DBE));
              if (ok) hasAdmin ? await AdminService.revokeAdminRole(uid) : await AdminService.grantAdminRole(uid);
            } else if (action == 'delete') {
              final ok = await showAdminConfirmDialog(context,
                  title: 'Delete User', message: 'Permanently deletes the user document. Cannot be undone.',
                  confirmLabel: 'Delete',
                  icon: const Icon(Icons.delete_forever, color: Color(0xFFEF5350), size: 40));
              if (ok) await AdminService.deleteUserDocument(uid);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'ban', child: Text(banned ? '✅ Unban' : '🚫 Ban', style: const TextStyle(color: Colors.white70, fontSize: 13))),
            const PopupMenuItem(value: 'admin', child: Text('👑 Toggle Admin', style: TextStyle(color: Colors.white70, fontSize: 13))),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ Delete', style: TextStyle(color: Color(0xFFEF9A9A), fontSize: 13))),
          ],
        ),
      ]),
    );
  }
}
