import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/shimmer.dart';
import 'provider.dart';
import 'detail.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Crisis Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(eventsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.cyan,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: eventsAsync.when(
        data: (events) => TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((tab) {
            final filtered = tab == 'ALL'
                ? events
                : events.where((e) => e.severity.toUpperCase() == tab).toList();
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No $tab events',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => EventCard(
                event: filtered[i],
                animIndex: i,
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => EventDetailPage(event: filtered[i]),
                    transitionsBuilder: (_, a, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(5, (_) => const ShimmerEventCard()),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text('Could not reach backend', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

