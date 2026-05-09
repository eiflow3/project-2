import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';

/// AppPreloadingScreen displays a premium, customized intro and database loading sequence
/// during startup for GilNor Gas Store. It simulates active milestoning for local db connections.
class AppPreloadingScreen extends StatefulWidget {
  const AppPreloadingScreen({super.key});

  @override
  State<AppPreloadingScreen> createState() => _AppPreloadingScreenState();
}

class _AppPreloadingScreenState extends State<AppPreloadingScreen> {
  int _currentStep = 0;
  
  // Real-world local sqlite startup steps
  final List<String> _steps = [
    'Connecting local database FFI bindings...',
    'Checking administrator credentials database...',
    'Loading active inventory catalogs...',
    'Initializing secure POS ledger systems...',
    'Launching GilNor Gas Store workspace...'
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Progress through database loading milestones every 400ms to keep experience responsive and snappy
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Premium Linear Radial Gradient Spotlight
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Central Core Intro Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Gas Flame Emblem representing GilNor Gas Store
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 24,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded, // Customized fire/gas store icon
                    color: AppColors.primaryLight,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // GilNor Store Typography
                const Text(
                  'GILNOR GAS STORE',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'OFFLINE LEDGER & POS SYSTEM',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Thin linear milestone progress line
                SizedBox(
                  width: 240,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _steps.length,
                      backgroundColor: AppColors.surfaceLight.withOpacity(0.25),
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                
                // Transitioning milestone text with animated cross-fades
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    _steps[_currentStep],
                    key: ValueKey<int>(_currentStep),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Subtle Secure Node footer label
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Secure Local-First Ledger Node  •  v2.5.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
