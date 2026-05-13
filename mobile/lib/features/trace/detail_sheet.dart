import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import '../../core/theme.dart';

class TraceDetailSheet extends StatelessWidget {
  final AgentTrace trace;
  const TraceDetailSheet({super.key, required this.trace});

  static Future<void> show(BuildContext context, AgentTrace trace) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TraceDetailSheet(trace: trace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(trace.status);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              _grabber(),
              _header(accent),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _summarySection(),
                    if (trace.prompt != null && trace.prompt!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _block(
                        label: 'PROMPT',
                        icon: Icons.input,
                        accent: AppColors.cyan,
                        body: trace.prompt!,
                        mono: true,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _block(
                      label: 'REASONING',
                      icon: Icons.psychology_outlined,
                      accent: AppColors.amber,
                      body: trace.reasoning.isEmpty
                          ? 'No reasoning recorded.'
                          : trace.reasoning,
                    ),
                    if (trace.decision != null && trace.decision!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _block(
                        label: 'DECISION',
                        icon: Icons.flag_outlined,
                        accent: accent,
                        body: trace.decision!,
                        mono: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grabber() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              trace.stage.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trace.agent,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _metaLine(),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metaLine() {
    final parts = <String>['#${trace.id}'];
    if (trace.eventId != null) parts.add('event #${trace.eventId}');
    parts.add(trace.status);
    if (trace.createdAt.isNotEmpty) parts.add(trace.createdAt);
    return parts.join(' · ');
  }

  Widget _summarySection() {
    if (trace.summary.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome,
              size: 14, color: AppColors.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trace.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block({
    required String label,
    required IconData icon,
    required Color accent,
    required String body,
    bool mono = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            _copyButton(body),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: SelectableText(
            body,
            style: TextStyle(
              fontFamily: mono ? 'monospace' : null,
              fontSize: mono ? 11.5 : 12.5,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _copyButton(String text) {
    return Builder(
      builder: (ctx) => InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (!ctx.mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Copy',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusAccent(String status) {
    switch (status) {
      case 'fallback':
        return AppColors.amber;
      case 'skipped':
        return AppColors.textMuted;
      case 'error':
        return AppColors.red;
      default:
        return AppColors.cyan;
    }
  }
}
