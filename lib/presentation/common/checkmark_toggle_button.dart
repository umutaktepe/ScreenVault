import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// 40px circular Checkmark Toggle Button that animates from Canary Yellow to Emerald Green
class CheckmarkToggleButton extends StatefulWidget {
  final bool isWatched;
  final ValueChanged<bool> onToggle;
  final double size;

  const CheckmarkToggleButton({
    super.key,
    required this.isWatched,
    required this.onToggle,
    this.size = 40.0,
  });

  @override
  State<CheckmarkToggleButton> createState() => _CheckmarkToggleButtonState();
}

class _CheckmarkToggleButtonState extends State<CheckmarkToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onToggle(!widget.isWatched);
  }

  @override
  Widget build(BuildContext context) {
    final isWatched = widget.isWatched;
    final backgroundColor = isWatched
        ? AppColors.functionalSuccess
        : AppColors.cardSurface.withValues(alpha: 0.9);
    final borderColor = isWatched
        ? AppColors.functionalSuccess
        : AppColors.primaryAccent;
    final iconColor = isWatched ? Colors.white : AppColors.primaryAccent;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isWatched ? AppColors.functionalSuccess : AppColors.primaryAccent)
                    .withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: isWatched
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('checked'),
                      color: Colors.white,
                      size: 24,
                    )
                  : Icon(
                      Icons.check_rounded,
                      key: const ValueKey('unchecked'),
                      color: iconColor,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
