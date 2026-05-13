import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';

class PipelinePage extends StatefulWidget {
  const PipelinePage({super.key});

  @override
  State<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends State<PipelinePage> {
  final List<_Stage> _stages = [
    _Stage('Ingest', Icons.download_outlined, '/ingest', 'POST', 'Pull from NASA, USGS & Weather APIs'),
    _Stage('Fuse', Icons.merge_type, '/fuse', 'POST', 'Cluster signals into crisis events via Gemini'),
    _Stage('Allocate', Icons.shuffle, '/allocate', 'POST', 'Optimize resource dispatch across crises'),
    _Stage('Simulate', Icons.play_circle_outline, '/simulate', 'POST', 'Predict outcomes and side effects'),
    _Stage('Notify', Icons.notifications_outlined, '/notify', 'POST', 'Generate stakeholder communications'),
    _Stage('Verify', Icons.verified_outlined, '/verify', 'POST', 'Detect false positives and escalate'),
  ];

  final List<String> _logs = [];
  bool _running = false;

  Future<void> _run(String path, String label) async {
    setState(() => _logs.add('▶ Running $label...'));
    try {
      final res = await post(path);
      setState(() => _logs.add('✅ $label complete: ${_summarize(res)}'));
    } catch (e) {
      setState(() => _logs.add('❌ $label failed: $e'));
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
      await _run(s.path, s.label);
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
                _PipelineFlow(stages: _stages, onTap: (s) => _run(s.path, s.label)),
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
                      children: _logs.asMap().entries.map((e) {
                        final isError = e.value.startsWith('❌');
                        final isSuccess = e.value.startsWith('✅');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isError
                                  ? AppColors.red
                                  : isSuccess
                                      ? AppColors.green
                                      : AppColors.textSecondary,
                              height: 1.5,
                            ),
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

class _Stage {
  final String label;
  final IconData icon;
  final String path;
  final String method;
  final String description;
  const _Stage(this.label, this.icon, this.path, this.method, this.description);
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

