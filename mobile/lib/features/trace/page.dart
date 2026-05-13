import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import 'detail_sheet.dart';

class TracePage extends StatefulWidget {
  const TracePage({super.key});

  @override
  State<TracePage> createState() => _TracePageState();
}

class _TracePageState extends State<TracePage> {
  static const _stages = <String>[
    'all',
    'fuse',
    'allocate',
    'simulate',
    'notify',
    'verify',
  ];

  String _stage = 'all';
  String? _agent;
  bool _loading = true;
  String? _error;
  List<AgentTrace> _traces = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qs = StringBuffer('?limit=200');
      if (_stage != 'all') qs.write('&stage=$_stage');
      if (_agent != null && _agent!.isNotEmpty) {
        qs.write('&agent=${Uri.encodeQueryComponent(_agent!)}');
      }
      final data = await get('/traces$qs');
      if (data is! List) {
        setState(() {
          _traces = const [];
          _loading = false;
        });
        return;
      }
      final out = data
          .whereType<Map>()
          .map((m) => AgentTrace.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      setState(() {
        _traces = out;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<String> get _agentOptions {
    final set = <String>{};
    for (final t in _traces) {
      if (t.agent.isNotEmpty) set.add(t.agent);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<AgentTrace> get _visible {
    if (_agent == null) return _traces;
    return _traces.where((t) => t.agent == _agent).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Agent Trace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filters(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scrollChips(
            label: 'STAGE',
            children: _stages.map((s) {
              final selected = _stage == s;
              return _chip(
                label: s == 'all' ? 'All stages' : s.toUpperCase(),
                selected: selected,
                onTap: () {
                  if (_stage == s) return;
                  setState(() => _stage = s);
                  _load();
                },
              );
            }).toList(),
          ),
          if (_agentOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _scrollChips(
              label: 'AGENT',
              children: [
                _chip(
                  label: 'All agents',
                  selected: _agent == null,
                  onTap: () => setState(() => _agent = null),
                ),
                ..._agentOptions.map(
                  (a) => _chip(
                    label: a,
                    selected: _agent == a,
                    onTap: () => setState(() => _agent = a),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scrollChips({required String label, required List<Widget> children}) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          for (final c in children) ...[
            c,
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyanDim : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.cyan.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? AppColors.cyan : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyan,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 44, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                'Could not load traces',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'No traces match these filters',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Run a pipeline stage to generate one',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _TraceTile(
        trace: items[i],
        onTap: () => TraceDetailSheet.show(ctx, items[i]),
      ),
    );
  }
}

class _TraceTile extends StatelessWidget {
  final AgentTrace trace;
  final VoidCallback onTap;
  const _TraceTile({required this.trace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(trace.status);
    final hasPrompt = (trace.prompt ?? '').isNotEmpty;
    final hasDecision = (trace.decision ?? '').isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    trace.stage.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trace.agent,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (trace.eventId != null)
                  Text(
                    'event #${trace.eventId}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            if (trace.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                trace.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            if (trace.reasoning.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                trace.reasoning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _facet('prompt', hasPrompt, AppColors.cyan),
                const SizedBox(width: 6),
                _facet('decision', hasDecision, accent),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _facet(String label, bool present, Color color) {
    final c = present ? color : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: present ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: present ? color.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check : Icons.remove,
            size: 9,
            color: c,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
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
