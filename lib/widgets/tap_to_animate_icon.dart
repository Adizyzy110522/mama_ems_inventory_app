import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Animation controller for tap effect on icons
class TapToAnimateIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final bool provideFeedback;

  const TapToAnimateIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.provideFeedback = true,
    super.key,
  });

  @override
  State<TapToAnimateIcon> createState() => _TapToAnimateIconState();
}

class _TapToAnimateIconState extends State<TapToAnimateIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Track if tap is in progress to prevent multiple rapid fires
  bool _isTapInProgress = false;
  DateTime _lastTapTime = DateTime.now();
  static const _debounceTime = Duration(milliseconds: 500); // Prevent too-rapid taps

  void _handleTapDown(_) {
    // Only animate if not already in a tap sequence
    if (!_isTapInProgress) {
      _controller.forward();
    }
  }

  void _handleTapUp(_) {
    // Check if enough time has passed since last tap to prevent accidental double-taps
    final now = DateTime.now();
    final difference = now.difference(_lastTapTime);
    
    if (difference.compareTo(_debounceTime) < 0) {
      // Too soon, just complete the animation without action
      _controller.reverse();
      return;
    }
    
    _lastTapTime = now;
    
    // Only process tap if not already in progress
    if (!_isTapInProgress) {
      _isTapInProgress = true;
      
      // Provide feedback before invoking callback which might take time
      if (widget.provideFeedback) {
        HapticFeedback.lightImpact();
      }
      
      // Execute the tap callback before animation completes to feel responsive
      widget.onTap();
      
      _controller.reverse().then((_) {
        // Reset flag when animation completes
        _isTapInProgress = false;
      });
      
      // Execute the tap callback
      widget.onTap();
    } else {
      // Just reverse the animation without calling onTap again
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse().then((_) {
      _isTapInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: widget.padding,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
