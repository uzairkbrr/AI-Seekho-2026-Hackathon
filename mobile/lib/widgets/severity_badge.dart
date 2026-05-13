import 'package:flutter/material.dart';
import '../core/theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool large;
  const SeverityBadge(this.severity, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    final dim = AppTheme.severityDim(severity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: dim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            severity.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: large ? 13 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

