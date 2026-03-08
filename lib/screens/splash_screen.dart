import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';
import 'home_screen.dart';

/// Animated landing screen with orbiting satellite
class SplashScreen extends StatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const SplashScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _launchMission() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, secAnim) => HomeScreen(
          sshController: widget.sshController,
          settingsController: widget.settingsController,
          lgController: widget.lgController,
        ),
        transitionsBuilder: (context, animation, secAnim, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgDark, Color(0xFF120827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.purple.withOpacity(0.4), width: 1),
                  ),
                  child: const Text(
                    '🌌  SPACE / ORBIT / VISUALIZATION  🛰️',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.purple,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'LG CONTROLLER',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 30,
                        letterSpacing: 3,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Liquid Galaxy Mission Control',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.cyan, letterSpacing: 0.8),
                ),
                const SizedBox(height: 56),

                // Orbital animation
                SizedBox(
                  width: 240,
                  height: 240,
                  child: AnimatedBuilder(
                    animation: _orbitController,
                    builder: (context, child) {
                      final angle = _orbitController.value * 2 * pi;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cyan.withOpacity(0.08),
                                width: 12,
                              ),
                            ),
                          ),
                          // Orbit ring
                          Container(
                            width: 182,
                            height: 182,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cyan.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Earth with pulse
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: const Text(
                              '🌍',
                              style: TextStyle(fontSize: 62),
                            ),
                          ),
                          // Satellite
                          Transform.translate(
                            offset: Offset(cos(angle) * 91, sin(angle) * 91),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.purple.withOpacity(0.25),
                                border: Border.all(
                                  color: AppTheme.purple.withOpacity(0.6),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.purple.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Text(
                                '🛰️',
                                style: TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 56),

                // Launch button
                GestureDetector(
                  onTap: _launchMission,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [AppTheme.purple, AppTheme.pink],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.purple
                                .withOpacity(0.4 * _pulseAnim.value),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'LAUNCH MISSION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to enter mission control',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
