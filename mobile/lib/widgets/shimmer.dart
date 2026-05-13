import 'package:flutter/material.dart';
import '../core/theme.dart';

class CiroShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const CiroShimmer({super.key, this.width = double.infinity, required this.height, this.radius = 12});

  @override
  State<CiroShimmer> createState() => _CiroShimmerState();
}

class _CiroShimmerState extends State<CiroShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [
              AppColors.card,
              AppColors.border,
              AppColors.card,
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerEventCard extends StatelessWidget {
  const ShimmerEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CiroShimmer(height: 14, radius: 6)),
              const SizedBox(width: 12),
              CiroShimmer(width: 70, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 12),
          CiroShimmer(height: 12, radius: 4),
          const SizedBox(height: 8),
          CiroShimmer(width: 200, height: 12, radius: 4),
        ],
      ),
    );
  }
}

