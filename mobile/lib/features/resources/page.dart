import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme.dart';
import '../../core/models.dart';
import '../../widgets/shimmer.dart';
import 'provider.dart';

class ResourcesPage extends ConsumerWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(resourcesProvider),
          ),
        ],
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No resources found. Run /api/resources/init',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FleetChart(resources: resources),
              const SizedBox(height: 24),
              Text(
                'FLEET STATUS',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...resources.asMap().entries.map((e) => _ResourceCard(resource: e.value, index: e.key)),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CiroShimmer(height: 80),
          )),
        ),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.red))),
      ),
    );
  }
}

class _FleetChart extends StatelessWidget {
  final List<Resource> resources;
  const _FleetChart({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fleet Availability Overview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: resources.fold<double>(0, (m, r) => r.totalUnits > m ? r.totalUnits.toDouble() : m) + 1,
                barGroups: resources.asMap().entries.map((e) {
                  final r = e.value;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: r.totalUnits.toDouble(), color: AppColors.border, width: 12, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: r.availableUnits.toDouble(), color: AppColors.cyan, width: 12, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final r = resources[v.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            r.resourceType.split('_').first,
                            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(AppColors.cyan, 'Available'),
              const SizedBox(width: 16),
              _legend(AppColors.border, 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final int index;
  const _ResourceCard({required this.resource, required this.index});

  @override
  Widget build(BuildContext context) {
    final used = resource.totalUnits - resource.availableUnits;
    final pct = resource.totalUnits > 0 ? resource.availableUnits / resource.totalUnits : 0.0;
    final color = pct > 0.6 ? AppColors.green : pct > 0.3 ? AppColors.amber : AppColors.red;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(resource.resourceType), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(resource.resourceType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.8)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${resource.availableUnits}/${resource.totalUnits}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                    Text('$used deployed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: Duration(milliseconds: 800 + index * 100),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ambulance': return Icons.local_hospital_outlined;
      case 'police': return Icons.local_police_outlined;
      case 'rescue_team': return Icons.people_outline;
      case 'shelter': return Icons.home_outlined;
      case 'generator': return Icons.bolt_outlined;
      case 'water_tanker': return Icons.water_drop_outlined;
      case 'drone': return Icons.personal_video_outlined;
      default: return Icons.work_outline;
    }
  }
}

