import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'severity_badge.dart';

class EventCard extends StatelessWidget {
  final CrisisEvent event;
  final VoidCallback? onTap;
  final int animIndex;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.animIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(event.severity);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + animIndex * 80),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: color, width: 3),
              top: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeverityBadge(event.severity),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(
                      Icons.people_outline,
                      event.affectedPopulation != null
                          ? '${(event.affectedPopulation! / 1000).toStringAsFixed(0)}K'
                          : 'Unknown',
                      AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    _chip(
                      Icons.radar,
                      '${event.affectedRadiusKm?.toStringAsFixed(0) ?? '?'} km',
                      AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    _chip(
                      Icons.shield_outlined,
                      '${(event.confidenceScore * 100).toStringAsFixed(0)}%',
                      AppColors.cyan,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${event.lat.toStringAsFixed(2)}, ${event.lng.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    _statusChip(event.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'active'
        ? AppColors.cyan
        : status == 'verified'
            ? AppColors.green
            : status == 'retracted'
                ? AppColors.red
                : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

