import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/event_card.dart';
import '../../widgets/shimmer.dart';
import '../events/provider.dart';
import '../resources/provider.dart';
import '../events/page.dart';
import '../events/detail.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final resourcesAsync = ref.watch(resourcesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: _hero(),
            ),
            title: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: _pulseAnim.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: _pulseAnim.value * 0.5),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CIRO',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('LIVE INTELLIGENCE'),
                  eventsAsync.when(
                    data: (events) {
                      final critical = events.where((e) => e.severity.toLowerCase() == 'critical').length;
                      return resourcesAsync.when(
                        data: (resources) {
                          final deployed = resources
                              .where((r) => r.availableUnits < r.totalUnits)
                              .length;
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              StatCard(
                                label: 'Active Crises',
                                value: '${events.length}',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.amber,
                                delay: 0,
                              ),
                              StatCard(
                                label: 'Critical Events',
                                value: '$critical',
                                icon: Icons.crisis_alert,
                                color: AppColors.red,
                                delay: 100,
                              ),
                              StatCard(
                                label: 'Resources Deployed',
                                value: '$deployed',
                                icon: Icons.local_hospital_outlined,
                                color: AppColors.cyan,
                                delay: 200,
                              ),
                              StatCard(
                                label: 'Fleet Available',
                                value: '${resources.length}',
                                icon: Icons.directions_car_outlined,
                                color: AppColors.green,
                                delay: 300,
                              ),
                            ],
                          );
                        },
                        loading: () => _shimmerGrid(),
                        error: (_, __) => _shimmerGrid(),
                      );
                    },
                    loading: () => _shimmerGrid(),
                    error: (_, __) => _shimmerGrid(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabelInline('RECENT EVENTS'),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EventsPage()),
                        ),
                        child: Text(
                          'View all →',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  eventsAsync.when(
                    data: (events) {
                      final recent = events.take(3).toList();
                      if (recent.isEmpty) {
                        return _emptyState('No crises detected', Icons.check_circle_outline);
                      }
                      return Column(
                        children: recent.asMap().entries.map((e) {
                          return EventCard(
                            event: e.value,
                            animIndex: e.key,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailPage(event: e.value),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => Column(
                      children: List.generate(3, (_) => const ShimmerEventCard()),
                    ),
                    error: (e, _) => _errorState('$e'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1F35), AppColors.bg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Crisis Intelligence',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Response Orchestrator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _sectionLabelInline(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(4, (_) => CiroShimmer(height: double.infinity)),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg, style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backend offline. Start the CIRO server.',
              style: TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

