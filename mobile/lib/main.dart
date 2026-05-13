import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/dashboard/page.dart';
import 'features/events/page.dart';
import 'features/resources/page.dart';
import 'features/notifications/page.dart';
import 'features/pipeline/page.dart';
import 'features/trace/page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: CiroApp()));
}

class CiroApp extends StatelessWidget {
  const CiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _idx = 0;

  final _pages = const [
    DashboardPage(),
    EventsPage(),
    ResourcesPage(),
    NotificationsPage(),
    PipelinePage(),
    TracePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: _NavBar(
        current: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int current;
  final void Function(int) onTap;

  const _NavBar({required this.current, required this.onTap});

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    (Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Events'),
    (Icons.local_hospital_outlined, Icons.local_hospital, 'Resources'),
    (Icons.notifications_outlined, Icons.notifications, 'Alerts'),
    (Icons.account_tree_outlined, Icons.account_tree, 'Pipeline'),
    (Icons.psychology_outlined, Icons.psychology, 'Trace'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final selected = e.key == current;
              final item = e.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.cyanDim : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected ? item.$2 : item.$1,
                              key: ValueKey(selected),
                              color: selected
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

