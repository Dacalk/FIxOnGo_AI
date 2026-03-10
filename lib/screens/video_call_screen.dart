import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Video call screen — live video call with a mechanic.
/// Shows full-screen remote video, a picture-in-picture local view,
/// caller info, and call control buttons.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isSpeaker = false;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final controlBg = dark ? const Color(0xFF1A2640) : Colors.white;
    final controlIconColor = dark ? Colors.white : Colors.black87;
    final controlLabelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen remote video placeholder ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5C8DB8),
                    const Color(0xFF4A7AA3),
                    const Color(0xFF3D6D96),
                    Colors.grey[700]!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Simulated mechanic silhouette
                  Center(
                    child: Icon(
                      Icons.build,
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Caller Info (top left) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dulan Thabrew',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE VIDEO',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Picture-in-Picture (top right) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Container(
              width: 100,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Placeholder for local camera
                    Container(
                      color: const Color(0xFFB8C9D8),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chat FAB (bottom right, above controls) ──
          Positioned(
            bottom: 140,
            right: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.grey[800]!.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // ── Call Controls Bar (bottom) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: controlBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute
                    _controlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: 'MUTE',
                      color: controlIconColor,
                      labelColor: controlLabelColor,
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    // Video
                    _controlButton(
                      icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                      label: 'VIDEO',
                      color: controlIconColor,
                      labelColor: controlLabelColor,
                      isActive: !_isVideoOn,
                      onTap: () => setState(() => _isVideoOn = !_isVideoOn),
                    ),
                    // End Call
                    _endCallButton(),
                    // Speaker
                    _controlButton(
                      icon: _isSpeaker
                          ? Icons.volume_up
                          : Icons.volume_up_outlined,
                      label: 'SPEAKER',
                      color: controlIconColor,
                      labelColor: controlLabelColor,
                      isActive: _isSpeaker,
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                    // Flip Camera
                    _controlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'FLIP',
                      color: controlIconColor,
                      labelColor: controlLabelColor,
                      isActive: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Regular control button
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
          const SizedBox(height: 4),
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

  /// Red end-call button
  Widget _endCallButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
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
    );
  }
}
