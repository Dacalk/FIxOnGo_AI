import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Voice call screen — standard audio call with a mechanic.
/// Shows caller avatar, name, status, and call control buttons.
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final controlBg = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final controlIconColor = dark ? Colors.white : Colors.black87;
    final controlLabelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final headerColor = dark ? Colors.white : AppColors.primaryBlue;
    final avatarRingColor = dark
        ? Colors.grey[700]!
        : AppColors.primaryBlue.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Dismiss button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dark ? AppColors.darkSurface : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: dark ? Colors.white : Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOICE CALL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Roadside Assistance',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── Avatar with pulse ring ──
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarRingColor, width: 3),
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dark
                            ? const Color(0xFF1E3350)
                            : Colors.grey[200],
                      ),
                      child: Icon(
                        Icons.build,
                        size: 60,
                        color: dark ? Colors.white54 : Colors.grey[500],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Caller name ──
            Text(
              'Sunil Perera',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),

            // ── Calling status ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Calling...',
                  style: TextStyle(fontSize: 16, color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Service tag ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Text(
                'Sri Lanka Assistance • Rider',
                style: TextStyle(
                  fontSize: 13,
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ── Controls ──
            Container(
              margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: controlBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _controlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic_off,
                    label: 'MUTE',
                    color: controlIconColor,
                    labelColor: controlLabelColor,
                    isActive: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // End Call
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/order-tracking',
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'END CALL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Speaker
                  _controlButton(
                    icon: Icons.volume_up,
                    label: 'SPEAKER',
                    color: controlIconColor,
                    labelColor: controlLabelColor,
                    isActive: _isSpeaker,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color labelColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
