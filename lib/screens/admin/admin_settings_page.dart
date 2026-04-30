import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AdminService.getAppSettings();
    setState(() { _settings = Map.from(s); _loading = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AdminService.updateAppSettings(_settings);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved ✓'), backgroundColor: Color(0xFF4CAF50)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4DBE)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader('App Status'),
        _ToggleTile('Maintenance Mode', 'Take the app offline for all non-admin users',
            _settings['maintenanceMode'] as bool? ?? false,
            (v) => setState(() => _settings['maintenanceMode'] = v),
            dangerColor: true),
        _ToggleTile('AI Chat Enabled', 'Allow users to access the Gemini AI assistant',
            _settings['aiChatEnabled'] as bool? ?? true,
            (v) => setState(() => _settings['aiChatEnabled'] = v)),

        const SizedBox(height: 24),
        _SectionHeader('Approval Settings'),
        _ToggleTile('Seller Approval Required', 'New sellers must be approved before going live',
            _settings['sellerApprovalRequired'] as bool? ?? true,
            (v) => setState(() => _settings['sellerApprovalRequired'] = v)),
        _ToggleTile('Deliver Approval Required', 'New delivery agents must be approved before going live',
            _settings['deliverApprovalRequired'] as bool? ?? true,
            (v) => setState(() => _settings['deliverApprovalRequired'] = v)),

        const SizedBox(height: 24),
        _SectionHeader('Service Configuration'),
        _NumberTile('Max Mechanic Radius (km)', _settings['maxMechanicRadiusKm']?.toString() ?? '20',
            (v) { final n = int.tryParse(v); if (n != null) setState(() => _settings['maxMechanicRadiusKm'] = n); }),
        _NumberTile('Service Fee (%)', _settings['serviceFeePercent']?.toString() ?? '10',
            (v) { final n = double.tryParse(v); if (n != null) setState(() => _settings['serviceFeePercent'] = n); }),
        _NumberTile('Minimum Fare (LKR)', _settings['minimumFare']?.toString() ?? '500',
            (v) { final n = int.tryParse(v); if (n != null) setState(() => _settings['minimumFare'] = n); }),

        const SizedBox(height: 24),
        _SectionHeader('Support'),
        _TextTile('Support Phone Number', _settings['supportPhone']?.toString() ?? '',
            (v) => setState(() => _settings['supportPhone'] = v)),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A4DBE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
  );
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dangerColor;
  const _ToggleTile(this.label, this.subtitle, this.value, this.onChanged, {this.dangerColor = false});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111D35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: (dangerColor && value)
            ? const Color(0xFFEF5350).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.06),
      ),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
      Switch(
        value: value,
        activeColor: dangerColor ? const Color(0xFFEF5350) : const Color(0xFF1A4DBE),
        onChanged: onChanged,
      ),
    ]),
  );
}

class _NumberTile extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _NumberTile(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111D35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      SizedBox(
        width: 100,
        child: TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ),
    ]),
  );
}

class _TextTile extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _TextTile(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111D35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      const SizedBox(width: 16),
      Expanded(
        child: TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
          onChanged: onChanged,
        ),
      ),
    ]),
  );
}
