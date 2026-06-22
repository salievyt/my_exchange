import 'package:flutter/material.dart';

/// A widget that fades in and slides up with a staggered delay.
///
/// Uses simple implicit animations instead of [AnimationController] +
/// [Future.delayed] to avoid cascading rebuilds on long lists.
/// Each item starts its animation independently when first mounted.
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

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Stagger: each item appears after the previous one with a delay.
    // Using a single delayed call per item — NOT during every rebuild.
    Future.delayed(widget.itemDuration * widget.index * 0.2, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : Offset(0, widget.offset),
      duration: widget.itemDuration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: widget.itemDuration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
