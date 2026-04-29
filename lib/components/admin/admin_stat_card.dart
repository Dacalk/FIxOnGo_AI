import 'package:flutter/material.dart';

class AdminStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final double? trend; // Positive or negative trend

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.trend,
  });

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Generate a default trend if not provided (just for UI preview, usually passed from parent)
    final double displayTrend = widget.trend ?? (widget.value.hashCode % 20 - 5).toDouble();
    final bool isPositive = displayTrend >= 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0)
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF111D35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered 
                ? widget.accentColor.withAlpha(127) 
                : Colors.white.withAlpha(20),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withAlpha(((_isHovered ? 0.2 : 0.05) * 255).toInt()),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accentColor.withAlpha(51)),
                  ),
                  child: Icon(widget.icon, color: widget.accentColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive 
                        ? Colors.greenAccent.withAlpha(25) 
                        : Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPositive 
                          ? Colors.greenAccent.withAlpha(51) 
                          : Colors.redAccent.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isPositive ? Colors.greenAccent : Colors.redAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${displayTrend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: widget.accentColor.withAlpha(204),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
