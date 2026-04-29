import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

enum MaskType { phone, email, name }

/// Displays PII masked by default. Tapping "Reveal" shows the real value
/// and writes an entry to the audit log.
class MaskedText extends StatefulWidget {
  final String value;
  final MaskType type;
  final String targetUid;
  final TextStyle? style;

  const MaskedText({
    super.key,
    required this.value,
    required this.type,
    required this.targetUid,
    this.style,
  });

  @override
  State<MaskedText> createState() => _MaskedTextState();
}

class _MaskedTextState extends State<MaskedText> {
  bool _revealed = false;

  String get _masked {
    switch (widget.type) {
      case MaskType.phone:
        if (widget.value.length < 6) return '•••••••••';
        final suffix = widget.value.substring(widget.value.length - 2);
        return '•••• •••• •• $suffix';
      case MaskType.email:
        final parts = widget.value.split('@');
        if (parts.length != 2) return '•••@•••.•••';
        final name = parts[0];
        final domain = parts[1];
        final masked = name.length > 2
            ? '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}'
            : '${name[0]}•';
        return '$masked@$domain';
      case MaskType.name:
        final words = widget.value.split(' ');
        if (words.isEmpty) return '•••';
        return '${words[0]} ${'•' * (words.length > 1 ? words[1].length : 3)}';
    }
  }

  void _reveal() async {
    setState(() => _revealed = true);
    await AdminService.logAction(
      'reveal_pii',
      widget.targetUid,
      {'field': widget.type.name, 'platform': 'web_admin'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _revealed ? widget.value : _masked,
          style: widget.style ??
              TextStyle(
                color: _revealed ? Colors.white : Colors.white54,
                fontSize: 13,
                fontFamily: _revealed ? null : 'monospace',
              ),
        ),
        const SizedBox(width: 6),
        if (!_revealed)
          GestureDetector(
            onTap: _reveal,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4DBE).withAlpha(51),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF1A4DBE).withAlpha(102)),
              ),
              child: const Text(
                'Reveal',
                style: TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
