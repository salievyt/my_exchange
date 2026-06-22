import 'package:flutter/material.dart';

/// A widget that fades in and slides up with a staggered delay.
///
/// Use this in list builders by passing the [index] to create a cascading
/// animation effect where each item appears after the previous one.
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;
  final Duration itemDuration;

  const StaggeredFadeIn({
    super.key,
    required this.child,
    required this.index,
    this.offset = 20.0,
    this.itemDuration = const Duration(milliseconds: 350),
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.itemDuration,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _translate = Tween<double>(begin: widget.offset, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0), // ease-out overshoot
      ),
    );
    // Stagger: each item starts 80ms after the previous one
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translate.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
