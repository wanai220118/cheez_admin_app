import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationHelper {
  /// Navigate with haptic feedback and bounce animation
  static Future<T?> navigateWithBounce<T extends Object?>(
    BuildContext context,
    Widget screen, {
    bool enableHaptic = true,
  }) async {
    if (enableHaptic) {
      HapticFeedback.selectionClick();
    }
    
    // Small delay for bounce effect
    await Future.delayed(Duration(milliseconds: 100));
    
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Bounce effect
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  /// Light haptic feedback for interactions
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback for important actions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Selection haptic feedback for taps
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}

