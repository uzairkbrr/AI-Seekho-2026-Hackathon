import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../trace/detail_sheet.dart';

class PipelinePage extends StatefulWidget {
  const PipelinePage({super.key});

  @override
  State<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends State<PipelinePage> {
  final List<_Stage> _stages = [
    _Stage('Ingest', Icons.download_outlined, '/ingest', null, 'Pull from NASA, USGS & Weather APIs'),
    _Stage('Fuse', Icons.merge_type, '/fuse', 'fuse', 'Cluster signals into crisis events via Gemini'),
    _Stage('Allocate', Icons.shuffle, '/allocate', 'allocate', 'Optimize resource dispatch across crises'),
    _Stage('Simulate', Icons.play_circle_outline, '/simulate', 'simulate', 'Predict outcomes and side effects'),
    _Stage('Notify', Icons.notifications_outlined, '/notify', 'notify', 'Generate stakeholder communications'),
    _Stage('Verify', Icons.verified_outlined, '/verify', 'verify', 'Detect false positives and escalate'),
  ];

  final List<_LogEntry> _logs = [];
  bool _running = false;

  Future<void> _run(_Stage stage) async {
    final startedAt = DateTime.now().toUtc();
    setState(() => _logs.add(_LogEntry.info('▶ Running ${stage.label}...')));
    try {
      final res = await post(stage.path);
      final traces = await _fetchTraces(stage.stageKey, startedAt);
      setState(() {
        _logs.add(_LogEntry.success(
          '✅ ${stage.label} complete: ${_summarize(res)}',
          traces: traces,
        ));
      });
    } catch (e) {
      setState(() => _logs.add(_LogEntry.error('❌ ${stage.label} failed: $e')));
    }
  }

  Future<List<AgentTrace>> _fetchTraces(String? stageKey, DateTime startedAt) async {
    if (stageKey == null) return const [];
    try {
      final since = startedAt.toIso8601String();
      final data = await get('/traces?stage=$stageKey&since=$since&limit=50');
      if (data is! List) return const [];
      final out = data
          .whereType<Map>()
          .map((m) => AgentTrace.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      return out;
    } catch (_) {
      return const [];
    }
  }

  String _summarize(dynamic res) {
    if (res is Map) {
      final keys = res.keys.where((k) => k != 'signals' && k != 'allocations' && k != 'notifications').toList();
      return keys.map((k) => '$k: ${res[k]}').join(', ');
    }
    if (res is List) return '${res.length} items returned';
    return '$res';
  }

  Future<void> _runAll() async {
    setState(() {
      _running = true;
      _logs.clear();
    });
    for (final s in _stages) {
      await _run(s);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pipeline Control')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PipelineFlow(stages: _stages, onTap: _run),
                const SizedBox(height: 24),
                if (_logs.isNotEmpty) ...[
                  Text(
                    'EXECUTION LOG',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logs.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: entry.color,
                                  height: 1.5,
                                ),
                              ),
                              if (entry.traces.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ...entry.traces.map(_ReasoningCard.new),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          _RunBar(running: _running, onRun: _runAll),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String text;
  final Color color;
  final List<AgentTrace> traces;
  const _LogEntry({required this.text, required this.color, this.traces = const []});

  factory _LogEntry.info(String t) =>
      _LogEntry(text: t, color: AppColors.textSecondary);
  factory _LogEntry.success(String t, {List<AgentTrace> traces = const []}) =>
      _LogEntry(text: t, color: AppColors.green, traces: traces);
  factory _LogEntry.error(String t) => _LogEntry(text: t, color: AppColors.red);
}

class _ReasoningCard extends StatelessWidget {
  final AgentTrace trace;
  const _ReasoningCard(this.trace);

  @override
  Widget build(BuildContext context) {
    final isFallback = trace.status == 'fallback';
    final isSkipped = trace.status == 'skipped';
    final accent = isFallback
        ? AppColors.amber
        : isSkipped
            ? AppColors.textMuted
            : AppColors.cyan;
    final hasPrompt = (trace.prompt ?? '').isNotEmpty;
    final hasDecision = (trace.decision ?? '').isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: InkWell(
        onTap: () => TraceDetailSheet.show(context, trace),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 11, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    trace.agent.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (trace.eventId != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '· event #${trace.eventId}',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isFallback || isSkipped)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trace.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
              if (trace.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  trace.summary,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
              if (trace.reasoning.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  trace.reasoning,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (hasPrompt || hasDecision) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (hasPrompt) ...[
                      _facet('prompt', AppColors.cyan),
                      const SizedBox(width: 6),
                    ],
                    if (hasDecision) _facet('decision', accent),
                    const Spacer(),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 9,
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 12, color: accent),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _facet(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Stage {
  final String label;
  final IconData icon;
  final String path;
  final String? stageKey;
  final String description;
  const _Stage(this.label, this.icon, this.path, this.stageKey, this.description);
}

class _PipelineFlow extends StatelessWidget {
  final List<_Stage> stages;
  final void Function(_Stage) onTap;
  const _PipelineFlow({required this.stages, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PIPELINE STAGES',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...stages.asMap().entries.map((e) {
          final s = e.value;
          final isLast = e.key == stages.length - 1;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + e.key * 80),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cyanDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                      ),
                      child: Icon(s.icon, color: AppColors.cyan, size: 20),
                    ),
                    if (!isLast)
                      Container(width: 1, height: 40, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 4),
                    child: GestureDetector(
                      onTap: () => onTap(s),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.label,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(s.description,
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.play_arrow_rounded, color: AppColors.cyan, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RunBar extends StatelessWidget {
  final bool running;
  final VoidCallback onRun;
  const _RunBar({required this.running, required this.onRun});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: running ? null : onRun,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: AppColors.bg,
            disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: running
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg)),
                    const SizedBox(width: 12),
                    Text('Running Pipeline...', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.bg)),
                  ],
                )
              : Text(
                  'Run Full Pipeline',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.bg),
                ),
        ),
      ),
    );
  }
}
