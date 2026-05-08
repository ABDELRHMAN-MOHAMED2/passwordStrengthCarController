import 'package:flutter/material.dart';

class FuturisticPanel extends StatelessWidget {
  const FuturisticPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF101722).withAlpha(226),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FuturisticStatusDot extends StatefulWidget {
  const FuturisticStatusDot({super.key, required this.active});

  final bool active;

  @override
  State<FuturisticStatusDot> createState() => _FuturisticStatusDotState();
}

class _FuturisticStatusDotState extends State<FuturisticStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? const Color(0xFF32E875) : Colors.redAccent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = widget.active ? 8 + (_controller.value * 12) : 4.0;
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withAlpha(130), blurRadius: glow),
            ],
          ),
        );
      },
    );
  }
}
