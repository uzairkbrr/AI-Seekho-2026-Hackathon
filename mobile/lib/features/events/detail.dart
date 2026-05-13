import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/severity_badge.dart';

class EventDetailPage extends StatefulWidget {
  final CrisisEvent event;
  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

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

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final color = AppTheme.severityColor(e.severity);

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

