import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../components/admin/admin_stat_card.dart';
import '../../components/admin/admin_charts.dart';
import '../../services/admin_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User / Role KPI Cards ──
          _StreamSection(
            stream: AdminService.usersStream(),
            label: 'Users & Roles',
            builder: (docs) {
              int users = 0, mechanics = 0, sellers = 0, delivers = 0, admins = 0, banned = 0;
              for (final d in docs) {
                final data = d.data() as Map<String, dynamic>;
                final roles = (data['roles'] as Map<String, dynamic>?) ?? {};
                if (roles.containsKey('user')) users++;
                if (roles.containsKey('mechanic')) mechanics++;
                if (roles.containsKey('seller')) sellers++;
                if (roles.containsKey('deliver')) delivers++;
                if (roles.containsKey('admin')) admins++;
                if (data['isBanned'] == true) banned++;
              }
              return Column(
                children: [
                  _KpiRow(stats: [
                    _Stat('Total Users',   users.toString(),     Icons.people_rounded,            const Color(0xFF1A4DBE)),
                    _Stat('Mechanics',     mechanics.toString(), Icons.build_rounded,              const Color(0xFF4CAF50)),
                    _Stat('Sellers',       sellers.toString(),   Icons.store_rounded,              const Color(0xFFFFC107)),
                    _Stat('Delivers',      delivers.toString(),  Icons.delivery_dining_rounded,    const Color(0xFF29B6F6)),
                    _Stat('Admins',        admins.toString(),    Icons.shield_rounded,             const Color(0xFFCE93D8)),
                    _Stat('Banned',        banned.toString(),    Icons.block_rounded,              const Color(0xFFEF5350)),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Insights & Role Distribution Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rolesCount = {
                        'user': users,
                        'mechanic': mechanics,
                        'seller': sellers,
                        'deliver': delivers,
                        'admin': admins,
                      };
                      final isWide = constraints.maxWidth > 800;
                      
                      final roleChart = _SectionCard(
                        title: 'User Role Distribution',
                        child: SizedBox(
                          height: 220,
                          child: AdminCharts.roleDistributionChart(rolesCount),
                        ),
                      );

                      final insights = _SectionCard(
                        title: 'Platform Insights',
                        child: SizedBox(
                          height: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _InsightRow(icon: Icons.trending_up, color: Colors.greenAccent, title: 'High Growth', subtitle: '+12% new mechanics this week'),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'disputed').snapshots(),
                                builder: (context, snap) {
                                  final count = snap.data?.docs.length ?? 0;
                                  return _InsightRow(icon: Icons.warning_amber_rounded, color: Colors.orangeAccent, title: 'Attention Required', subtitle: '$count disputed requests pending');
                                },
                              ),
                              _InsightRow(icon: Icons.attach_money_rounded, color: Colors.blueAccent, title: 'Revenue Trend', subtitle: 'Steady growth in daily transactions'),
                            ],
                          ),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: roleChart),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: insights),
                          ],
                        );
                      }
                      return Column(children: [roleChart, const SizedBox(height: 24), insights]);
                    }
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Charts Row (Requests over time) ──
          _StreamSection(
            stream: FirebaseFirestore.instance.collection('requests').snapshots(),
            label: 'daily requests',
            builder: (docs) {
              final now = DateTime.now();
              List<int> dailyCounts = List.filled(7, 0);
              for (final d in docs) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (ts != null) {
                  final diff = now.difference(ts.toDate()).inDays;
                  if (diff >= 0 && diff < 7) {
                    dailyCounts[6 - diff]++;
                  }
                }
              }
              return _SectionCard(
                title: 'Daily Service Requests (Last 7 Days)',
                child: SizedBox(
                  height: 200,
                  child: AdminCharts.dailyRequestsChart(dailyCounts),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Bottom row: Requests | Revenue | App Health ──
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 800;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _requestsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _revenueCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _healthCard()),
                  ],
                );
              }
              return Column(children: [
                _requestsCard(),
                const SizedBox(height: 16),
                _revenueCard(),
                const SizedBox(height: 16),
                _healthCard(),
              ]);
            },
          ),

          const SizedBox(height: 24),

          // ── Recent Audit Log ──
          _SectionCard(
            title: 'Recent Admin Actions',
            child: _StreamSection(
              stream: AdminService.auditLogsStream(),
              label: 'audit log',
              builder: (docs) {
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No admin actions recorded yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  );
                }
                return Column(
                  children: docs.take(8).map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final action = (data['action'] ?? '').toString();
                    final email  = (data['adminEmail'] ?? '').toString();
                    final ts     = data['timestamp'] as Timestamp?;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        const Icon(Icons.history_rounded, color: Colors.white24, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          action.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 11,
                              fontWeight: FontWeight.w600),
                        )),
                        Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(width: 8),
                        if (ts != null)
                          Text(_ago(ts.toDate()),
                              style: const TextStyle(color: Colors.white24, fontSize: 11)),
                      ]),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestsCard() {
    return _SectionCard(
      title: 'Service Requests',
      child: _StreamSection(
        // Simple query — no orderBy to avoid needing a composite index
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        label: 'requests',
        builder: (docs) {
          int pending = 0, active = 0, completed = 0, disputed = 0, total = docs.length;
          for (final d in docs) {
            final s = (d.data() as Map<String, dynamic>)['status']?.toString() ?? '';
            if (s == 'pending')                     pending++;
            else if (s == 'accepted' || s == 'arriving') active++;
            else if (s == 'completed')              completed++;
            else if (s == 'disputed')               disputed++;
          }
          return Column(children: [
            _Row('Total',     total,     Colors.white70),
            _Row('Pending',   pending,   const Color(0xFFFFC107)),
            _Row('Active',    active,    const Color(0xFF4CAF50)),
            _Row('Completed', completed, const Color(0xFF1A4DBE)),
            _Row('Disputed',  disputed,  const Color(0xFFEF5350)),
          ]);
        },
      ),
    );
  }

  Widget _revenueCard() {
    return _SectionCard(
      title: 'Revenue',
      child: _StreamSection(
        // Simple query — no orderBy needed for totals
        stream: FirebaseFirestore.instance.collection('payments').snapshots(),
        label: 'payments',
        builder: (docs) {
          num total = 0, today = 0;
          final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
          for (final d in docs) {
            final data  = d.data() as Map<String, dynamic>;
            
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
            _Row('Total Transactions', docs.length, const Color(0xFF1A4DBE)),
            _Row("Today's Revenue (LKR)", today.toInt(), const Color(0xFF4CAF50)),
            _Row('All-time Revenue (LKR)', total.toInt(), Colors.white70),
          ]);
        },
      ),
    );
  }

  Widget _healthCard() {
    return _SectionCard(
      title: 'App Health',
      child: _StreamSection(
        stream: FirebaseFirestore.instance.collection('app_settings').snapshots(),
        label: 'app settings',
        builder: (docs) {
          final settings = (docs.isNotEmpty
                  ? docs.first.data() as Map<String, dynamic>
                  : null) ??
              AdminService.defaultSettings;
          final maintenance = settings['maintenanceMode'] as bool? ?? false;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Maintenance Mode',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                value: maintenance,
                activeColor: const Color(0xFFEF5350),
                onChanged: (v) => AdminService.updateAppSettings({'maintenanceMode': v}),
              ),
            ]),
            const Divider(color: Colors.white10),
            _BoolRow('AI Chat', settings['aiChatEnabled'] as bool? ?? true),
            _BoolRow('Seller Approval', settings['sellerApprovalRequired'] as bool? ?? true),
            _BoolRow('Deliver Approval', settings['deliverApprovalRequired'] as bool? ?? true),
          ]);
        },
      ),
    );
  }

  static String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1)   return '${d.inMinutes}m ago';
    if (d.inDays < 1)    return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ── Reusable stream wrapper with loading + error states ──────────────────────
class _StreamSection extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  final Widget Function(List<QueryDocumentSnapshot>) builder;

  const _StreamSection({
    required this.stream,
    required this.label,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1A4DBE), strokeWidth: 2),
                  const SizedBox(height: 16),
                  Text('Loading $label...', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF5350).withAlpha(76)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF9A9A), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Could not load $label: ${snap.error}',
                style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
              )),
            ]),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: builder(snap.data?.docs ?? []),
        );
      },
    );
  }
}

// ── KPI row ──────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final List<_Stat> stats;
  const _KpiRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = (constraints.maxWidth / 220).floor().clamp(2, 6);
      final itemWidth = (constraints.maxWidth - (crossCount - 1) * 16) / crossCount;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: stats.map((s) => SizedBox(
          width: itemWidth,
          child: AdminStatCard(
            label: s.label, value: s.value,
            icon: s.icon, accentColor: s.color,
          ),
        )).toList(),
      );
    });
  }
}

class _Stat {
  final String label, value; final IconData icon; final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

// ── Section card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF15233E).withAlpha(204),
            const Color(0xFF0D1626).withAlpha(229),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3)),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final num value; final Color color;
  const _Row(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      Text(value.toString(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    ]),
  );
}

class _BoolRow extends StatelessWidget {
  final String label; final bool value;
  const _BoolRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF4CAF50).withAlpha(38)
              : const Color(0xFFEF5350).withAlpha(38),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(value ? 'ON' : 'OFF',
            style: TextStyle(
              color: value ? const Color(0xFF81C784) : const Color(0xFFEF9A9A),
              fontSize: 11, fontWeight: FontWeight.bold,
            )),
      ),
    ]),
  );
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InsightRow({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(76)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
