import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/severity_badge.dart';
import 'provider.dart';
import 'response_map.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final CrisisEvent event;
  const EventDetailPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _busy = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSimulate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMsg = 'Simulating response...';
    });
    try {
      final res = await post('/simulate');
      ref.invalidate(eventResponseProvider(widget.event.id));
      if (!mounted) return;
      setState(() => _statusMsg = _simSummary(res));
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Simulate failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runTick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMsg = 'Advancing dispatches...';
    });
    try {
      final res = await post('/simulate/tick');
      ref.invalidate(eventResponseProvider(widget.event.id));
      if (!mounted) return;
      final advanced = res is Map ? res['advanced'] ?? 0 : 0;
      final arrived = res is Map ? res['arrived'] ?? 0 : 0;
      setState(() =>
          _statusMsg = 'Advanced $advanced track(s) · $arrived on-scene');
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Tick failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _simSummary(dynamic res) {
    if (res is Map) {
      return 'Dispatches ${res['dispatches_created'] ?? 0} · '
          'Tickets ${res['tickets_created'] ?? 0} · '
          'Log ${res['log_entries_created'] ?? 0} · '
          'Zones ${res['alert_zones_created'] ?? 0} · '
          'Closures ${res['closures_created'] ?? 0}';
    }
    return 'Done';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final color = AppTheme.severityColor(e.severity);
    final responseAsync = ref.watch(eventResponseProvider(e.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.bg,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.25),
                        AppColors.bg,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SeverityBadge(e.severity, large: true),
                        const SizedBox(height: 10),
                        Text(
                          e.eventType,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${e.lat.toStringAsFixed(4)}, ${e.lng.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _impactGrid(e),
                    const SizedBox(height: 24),
                    _section(
                      'BEFORE / AFTER IMPACT',
                      _projectedImpact(e, responseAsync),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'RESPONSE ACTIONS',
                      _responseSection(e, responseAsync),
                    ),
                    const SizedBox(height: 24),
                    _section('AI ASSESSMENT', _assessment(e)),
                    const SizedBox(height: 24),
                    _section('SIGNAL SOURCES', _signals(e.signals)),
                    const SizedBox(height: 24),
                    _section('LOCATION INTELLIGENCE', _locationCard(e)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _impactGrid(CrisisEvent e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('IMPACT METRICS'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _metricCard('Affected', '${((e.affectedPopulation ?? 0) / 1000).toStringAsFixed(0)}K', Icons.people_outline, AppColors.cyan),
            _metricCard('Radius', '${e.affectedRadiusKm?.toStringAsFixed(0) ?? '?'} km', Icons.radar, AppColors.amber),
            _metricCard('Duration', '${e.expectedDurationHours?.toStringAsFixed(0) ?? '?'} hrs', Icons.timer_outlined, AppColors.orange),
            _metricCard('Confidence', '${(e.confidenceScore * 100).toStringAsFixed(0)}%', Icons.shield_outlined, AppColors.green),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _assessment(CrisisEvent e) {
    return Column(
      children: [
        _infoRow('Spread Risk', e.spreadRisk ?? 'Unknown', _riskColor(e.spreadRisk)),
        _infoRow('Peak Impact', e.peakImpactTime ?? 'Unknown', AppColors.textSecondary),
        _infoRow('Contradiction', e.contradictionLevel, _contradictionColor(e.contradictionLevel)),
        _infoRow('Uncertainty', e.uncertaintyRange ?? 'Unknown', AppColors.textSecondary),
        if (e.likelyEvolution != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cyanDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.cyan, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.likelyEvolution!,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _projectedImpact(
    CrisisEvent e,
    AsyncValue<EventResponseState> async,
  ) {
    return async.when(
      data: (state) => _comparisonCard(e, state),
      loading: () => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.cyan, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _comparisonCard(CrisisEvent e, EventResponseState state) {
    final projections = _project(e, state);
    final hasAction = !state.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _scenarioHeader(
                    'BEFORE', AppColors.red, Icons.dangerous_outlined),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _scenarioHeader(
                    'AFTER', AppColors.cyan, Icons.shield_outlined),
              ),
            ],
          ),
          Container(height: 1, color: AppColors.border),
          for (var i = 0; i < projections.length; i++) ...[
            _compareRow(projections[i]),
            if (i < projections.length - 1)
              Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.border.withValues(alpha: 0.5)),
          ],
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  hasAction ? Icons.trending_down : Icons.info_outline,
                  size: 14,
                  color: hasAction
                      ? AppColors.green
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasAction
                        ? _summary(projections)
                        : 'Run Simulate to see the after-response impact.',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasAction
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scenarioHeader(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareRow(_Projection p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(p.icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                p.label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (p.delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.delta!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _valueChip(
                  p.noActionLabel,
                  AppColors.red,
                  p.noActionPct,
                  alignEnd: true,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: _valueChip(
                  p.withActionLabel,
                  AppColors.cyan,
                  p.withActionPct,
                  alignEnd: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueChip(String value, Color color, double pct,
      {required bool alignEnd}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment:
                alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: v == 0 ? 0.001 : v,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_Projection> _project(CrisisEvent e, EventResponseState state) {
    final pop = (e.affectedPopulation ?? 0).toDouble();
    final hours = e.expectedDurationHours ?? 24;
    final sev = e.severity.toLowerCase();
    final casualtyRate = sev == 'critical'
        ? 0.08
        : sev == 'high'
            ? 0.04
            : sev == 'medium'
                ? 0.015
                : 0.005;
    final noCasualty = pop * casualtyRate;

    final dispatchUnits =
        state.dispatches.fold<int>(0, (s, d) => s + d.units);
    final avgEta = state.dispatches.isEmpty
        ? double.infinity
        : state.dispatches
                .map((d) => d.etaMinutes)
                .reduce((a, b) => a + b) /
            state.dispatches.length;
    final etaFactor =
        avgEta.isInfinite ? 0.0 : (1.0 - (avgEta / 60)).clamp(0.0, 1.0);
    final unitFactor = (dispatchUnits / 8).clamp(0.0, 1.0);
    final reduction = state.dispatches.isEmpty
        ? 0.0
        : (etaFactor * 0.5 + unitFactor * 0.5) * 0.85;
    final withCasualty = noCasualty * (1 - reduction);

    final alerted =
        state.zones.fold<int>(0, (s, z) => s + z.broadcastCount).toDouble();
    final alertCoverage =
        pop == 0 ? 0.0 : (alerted / pop).clamp(0.0, 1.0);

    final contained = (state.closures.length * 12).clamp(0, 60).toDouble();

    final recRed = (state.dispatches.isEmpty ? 0.0 : 0.3) +
        (state.closures.isEmpty ? 0.0 : 0.15) +
        (state.zones.isEmpty ? 0.0 : 0.1);
    final clampedRec = recRed.clamp(0.0, 0.6);
    final withHours = hours * (1 - clampedRec);

    return [
      _Projection(
        label: 'CASUALTIES',
        noActionLabel: _fmtCount(noCasualty),
        withActionLabel: _fmtCount(withCasualty),
        noActionPct: 1.0,
        withActionPct: noCasualty == 0
            ? 0.0
            : (withCasualty / noCasualty).clamp(0.0, 1.0),
        delta: reduction == 0
            ? null
            : '-${(reduction * 100).toStringAsFixed(0)}%',
        icon: Icons.warning_amber_rounded,
      ),
      _Projection(
        label: 'POPULATION ALERTED',
        noActionLabel: '0',
        withActionLabel: _fmtCount(alerted),
        noActionPct: 0.0,
        withActionPct: alertCoverage,
        delta: alerted == 0
            ? null
            : '+${(alertCoverage * 100).toStringAsFixed(0)}%',
        icon: Icons.campaign_outlined,
      ),
      _Projection(
        label: 'HAZARD CONTAINMENT',
        noActionLabel: '0%',
        withActionLabel: '${contained.toStringAsFixed(0)}%',
        noActionPct: 0.0,
        withActionPct: contained / 100,
        delta: contained == 0
            ? null
            : '+${contained.toStringAsFixed(0)}%',
        icon: Icons.block_outlined,
      ),
      _Projection(
        label: 'RECOVERY TIME',
        noActionLabel: '${hours.toStringAsFixed(0)}h',
        withActionLabel: '${withHours.toStringAsFixed(0)}h',
        noActionPct: 1.0,
        withActionPct: hours == 0 ? 0.0 : withHours / hours,
        delta: clampedRec == 0
            ? null
            : '-${(clampedRec * 100).toStringAsFixed(0)}%',
        icon: Icons.timer_outlined,
      ),
    ];
  }

  String _summary(List<_Projection> ps) {
    final parts = <String>[];
    for (final p in ps) {
      if (p.delta == null) continue;
      if (p.label == 'CASUALTIES') {
        parts.add('${p.delta!.replaceAll('-', '')} fewer casualties');
      } else if (p.label == 'POPULATION ALERTED') {
        parts.add('${p.withActionLabel} alerted');
      } else if (p.label == 'RECOVERY TIME') {
        parts.add('recovery ${p.delta!.replaceAll('-', '')} faster');
      }
    }
    if (parts.isEmpty) return 'Response active — see after-state above.';
    return 'After response: ${parts.join(' · ')}.';
  }

  String _fmtCount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _responseSection(
    CrisisEvent e,
    AsyncValue<EventResponseState> async,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        async.when(
          data: (state) => _responseBody(e, state),
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.cyan,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.redDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Could not load response state: $err',
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _simControls(),
      ],
    );
  }

  Widget _responseBody(CrisisEvent e, EventResponseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponseMap(
          event: e,
          closures: state.closures,
          dispatches: state.dispatches,
          zones: state.zones,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _legendDot(AppColors.red, 'Closures'),
            const SizedBox(width: 12),
            _legendDot(AppColors.cyan, 'Dispatch'),
            const SizedBox(width: 12),
            _legendDot(AppTheme.severityColor(e.severity), 'Alert zone'),
          ],
        ),
        const SizedBox(height: 14),
        if (state.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No response actions yet. Run Simulate to dispatch '
                    'units, close affected routes, and broadcast alerts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _ticketList(state.tickets),
          if (state.tickets.isNotEmpty) const SizedBox(height: 12),
          _dispatchList(state.dispatches),
          if (state.dispatches.isNotEmpty) const SizedBox(height: 12),
          _closureList(state.closures),
          if (state.closures.isNotEmpty) const SizedBox(height: 12),
          _zoneList(state.zones),
          if (state.zones.isNotEmpty) const SizedBox(height: 12),
          _alertLog(state.log),
        ],
      ],
    );
  }

  Widget _dispatchList(List<DispatchTrack> tracks) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('DISPATCH (${tracks.length})'),
        ...tracks.map((t) {
          final pct = (t.progress.clamp(0.0, 1.0) * 100).round();
          final statusColor = t.status == 'on_scene'
              ? AppColors.green
              : t.status == 'enroute'
                  ? AppColors.cyan
                  : AppColors.textSecondary;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      'Unit #${t.resourceId} · ${t.units} unit(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: t.progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  'ETA ${t.etaMinutes.toStringAsFixed(1)} min · $pct%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _closureList(List<RoadClosure> closures) {
    if (closures.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('ROAD CLOSURES (${closures.length})'),
        ...closures.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.redDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_outlined,
                    size: 14, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        c.reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  c.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _zoneList(List<AlertZone> zones) {
    if (zones.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('ALERT BROADCAST (${zones.length})'),
        ...zones.map((z) {
          final color = AppTheme.severityColor(z.severity);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, size: 14, color: color),
                    const SizedBox(width: 8),
                    Text(
                      'Radius ${z.radiusKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${z.broadcastCount} ppl',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  z.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _ticketList(List<EmergencyTicket> tickets) {
    if (tickets.isEmpty) return const SizedBox.shrink();
    final open = tickets.where((t) => t.status == 'open').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('EMERGENCY TICKETS (${tickets.length} · $open open)'),
        ...tickets.map((t) {
          final accent = _categoryColor(t.category);
          final statusColor = _ticketStatusColor(t.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_categoryIcon(t.category), size: 14, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      t.ticketCode,
                      style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _priorityColor(t.priority)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.priority,
                        style: TextStyle(
                          fontSize: 9,
                          color: _priorityColor(t.priority),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      t.assignee,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (t.etaMinutes != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.timer_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'ETA ${t.etaMinutes!.toStringAsFixed(1)} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _alertLog(List<AlertLogEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final ordered = [...entries]..sort((a, b) => b.id.compareTo(a.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('ALERT LOG (${entries.length})'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ordered.take(20).map((entry) {
              final color = _logLevelColor(entry.level);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.channel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.level.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatLogTime(entry.createdAt),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (entry.message.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'dispatch':
        return AppColors.cyan;
      case 'traffic_control':
        return AppColors.red;
      case 'alert':
        return AppColors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'dispatch':
        return Icons.local_shipping_outlined;
      case 'traffic_control':
        return Icons.block_outlined;
      case 'alert':
        return Icons.campaign_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'P1':
        return AppColors.red;
      case 'P2':
        return AppColors.orange;
      case 'P3':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  Color _ticketStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.green;
      case 'on_scene':
        return AppColors.green;
      case 'in_progress':
        return AppColors.amber;
      default:
        return AppColors.cyan;
    }
  }

  Color _logLevelColor(String level) {
    switch (level) {
      case 'critical':
        return AppColors.red;
      case 'warn':
        return AppColors.amber;
      default:
        return AppColors.cyan;
    }
  }

  String _formatLogTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Widget _simControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _runSimulate,
                icon: const Icon(Icons.play_circle_outline, size: 16),
                label: const Text('Simulate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.bg,
                  disabledBackgroundColor:
                      AppColors.cyan.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _runTick,
                icon: const Icon(Icons.fast_forward_outlined, size: 16),
                label: const Text('Advance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        if (_statusMsg != null) ...[
          const SizedBox(height: 8),
          Text(
            _statusMsg!,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _subLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _signals(List<Signal> signals) {
    if (signals.isEmpty) {
      return Text('No signals', style: TextStyle(color: AppColors.textMuted));
    }
    return Column(
      children: signals.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: s.isSuspicious ? AppColors.redDim : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: s.isSuspicious ? AppColors.red.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sourceIcon(s.source),
                  const SizedBox(width: 8),
                  Text(
                    s.source.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (s.isSuspicious)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.redDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('SUSPICIOUS', style: TextStyle(color: AppColors.red, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(width: 6),
                  _credBar(s.credibilityScore),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.content,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _locationCard(CrisisEvent e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LATITUDE', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      e.lat.toStringAsFixed(6),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.cyan),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LONGITUDE', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      e.lng.toStringAsFixed(6),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.cyan),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _GridPainter(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.red, size: 24),
                      Text(
                        '${e.lat.toStringAsFixed(2)}, ${e.lng.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credBar(double score) {
    return Row(
      children: [
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(width: 4),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: score,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: score > 0.7 ? AppColors.green : score > 0.4 ? AppColors.amber : AppColors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _section(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(title),
        content,
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5),
      ),
    );
  }

  Widget _sourceIcon(String source) {
    final icon = source.contains('weather')
        ? Icons.cloud_outlined
        : source.contains('quake') || source.contains('usgs')
            ? Icons.landscape_outlined
            : source.contains('nasa')
                ? Icons.satellite_alt_outlined
                : Icons.article_outlined;
    return Icon(icon, size: 14, color: AppColors.cyan);
  }

  Color _riskColor(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'high': return AppColors.red;
      case 'medium': return AppColors.amber;
      default: return AppColors.green;
    }
  }

  Color _contradictionColor(String level) {
    switch (level.toLowerCase()) {
      case 'high': return AppColors.red;
      case 'low': return AppColors.amber;
      default: return AppColors.green;
    }
  }
}

class _Projection {
  final String label;
  final String noActionLabel;
  final String withActionLabel;
  final double noActionPct;
  final double withActionPct;
  final String? delta;
  final IconData icon;
  const _Projection({
    required this.label,
    required this.noActionLabel,
    required this.withActionLabel,
    required this.noActionPct,
    required this.withActionPct,
    required this.delta,
    required this.icon,
  });
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    const gap = 20.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

