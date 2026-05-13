import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/models.dart' as ciro;
import '../../widgets/shimmer.dart';
import 'provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notifAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          final grouped = <String, List<ciro.Notification>>{};
          for (final n in notifs) {
            grouped.putIfAbsent(n.recipient, () => []).add(n);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.expand((entry) {
              return [
                _GroupHeader(recipient: entry.key),
                const SizedBox(height: 8),
                ...entry.value.asMap().entries.map((e) => _NotifCard(notif: e.value, index: e.key)),
                const SizedBox(height: 16),
              ];
            }).toList(),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CiroShimmer(height: 90),
          )),
        ),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.red))),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String recipient;
  const _GroupHeader({required this.recipient});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _recipientMeta(recipient);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          recipient.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1),
        ),
      ],
    );
  }

  (IconData, Color) _recipientMeta(String r) {
    switch (r.toLowerCase()) {
      case 'public': return (Icons.people_outline, AppColors.cyan);
      case 'emergency_services': return (Icons.local_police_outlined, AppColors.red);
      case 'hospitals': return (Icons.local_hospital_outlined, AppColors.green);
      case 'utility': return (Icons.bolt_outlined, AppColors.amber);
      case 'transport': return (Icons.directions_car_outlined, AppColors.orange);
      case 'media': return (Icons.campaign_outlined, AppColors.textSecondary);
      default: return (Icons.person_outline, AppColors.textSecondary);
    }
  }
}

class _NotifCard extends StatelessWidget {
  final ciro.Notification notif;
  final int index;
  const _NotifCard({required this.notif, required this.index});

  @override
  Widget build(BuildContext context) {
    final urgencyColor = notif.urgency == 'Immediate'
        ? AppColors.red
        : notif.urgency == 'Urgent'
            ? AppColors.amber
            : AppColors.green;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(notif.subject,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    notif.urgency.toUpperCase(),
                    style: TextStyle(fontSize: 9, color: urgencyColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(notif.message,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                _channelChip(notif.channel),
                const Spacer(),
                Text('Event #${notif.eventId}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelChip(String ch) {
    final icon = ch == 'Dashboard'
        ? Icons.dashboard_outlined
        : ch == 'SMS'
            ? Icons.sms_outlined
            : ch == 'Email'
                ? Icons.email_outlined
                : Icons.radio_outlined;
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(ch, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

