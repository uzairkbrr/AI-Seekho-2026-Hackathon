import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/theme.dart';

class ResponseMap extends StatelessWidget {
  final CrisisEvent event;
  final List<RoadClosure> closures;
  final List<DispatchTrack> dispatches;
  final List<AlertZone> zones;

  const ResponseMap({
    super.key,
    required this.event,
    required this.closures,
    required this.dispatches,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.border),
          ),
          child: CustomPaint(
            painter: _ResponseMapPainter(
              event: event,
              closures: closures,
              dispatches: dispatches,
              zones: zones,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseMapPainter extends CustomPainter {
  final CrisisEvent event;
  final List<RoadClosure> closures;
  final List<DispatchTrack> dispatches;
  final List<AlertZone> zones;

  _ResponseMapPainter({
    required this.event,
    required this.closures,
    required this.dispatches,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _bounds();
    final span = math.max(bounds.spanLat, bounds.spanLng);
    final pad = math.max(span * 0.18, 0.01);
    final left = bounds.minLng - pad;
    final right = bounds.maxLng + pad;
    final top = bounds.maxLat + pad;
    final bottom = bounds.minLat - pad;

    Offset project(double lat, double lng) {
      final dx = (lng - left) / (right - left);
      final dy = (top - lat) / (top - bottom);
      return Offset(dx * size.width, dy * size.height);
    }

    _drawGrid(canvas, size);

    // Alert zones — circles centered on event, radius approximate.
    for (final z in zones) {
      final center = project(z.centerLat, z.centerLng);
      final edge = project(
        z.centerLat,
        z.centerLng + (z.radiusKm / 111.0),
      );
      final r = (edge - center).distance.clamp(8.0, size.width);
      final color = _severityColor(z.severity);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Road closures — red dashed segments.
    for (final c in closures) {
      _drawDashedLine(
        canvas,
        project(c.fromLat, c.fromLng),
        project(c.toLat, c.toLng),
        AppColors.red,
      );
    }

    // Dispatch tracks — cyan paths from origin to event, with progress marker.
    for (final d in dispatches) {
      final a = project(d.fromLat, d.fromLng);
      final b = project(d.toLat, d.toLng);
      final cur = project(d.currentLat, d.currentLng);
      final dim = AppColors.cyan.withValues(alpha: 0.3);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = dim
          ..strokeWidth = 1.0,
      );
      canvas.drawLine(
        a,
        cur,
        Paint()
          ..color = AppColors.cyan
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // Origin pin
      canvas.drawCircle(
        a,
        3,
        Paint()..color = AppColors.cyan.withValues(alpha: 0.7),
      );
      // Moving marker
      canvas.drawCircle(
        cur,
        5,
        Paint()..color = AppColors.cyan,
      );
      canvas.drawCircle(
        cur,
        9,
        Paint()
          ..color = AppColors.cyan.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
    }

    // Event marker
    final ep = project(event.lat, event.lng);
    final severity = _severityColor(event.severity);
    canvas.drawCircle(
      ep,
      14,
      Paint()..color = severity.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      ep,
      6,
      Paint()..color = severity,
    );
    canvas.drawCircle(
      ep,
      6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double drawn = 0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  _Bounds _bounds() {
    final lats = <double>[event.lat];
    final lngs = <double>[event.lng];
    for (final c in closures) {
      lats..add(c.fromLat)..add(c.toLat);
      lngs..add(c.fromLng)..add(c.toLng);
    }
    for (final d in dispatches) {
      lats..add(d.fromLat)..add(d.toLat)..add(d.currentLat);
      lngs..add(d.fromLng)..add(d.toLng)..add(d.currentLng);
    }
    for (final z in zones) {
      final dr = z.radiusKm / 111.0;
      lats..add(z.centerLat - dr)..add(z.centerLat + dr);
      lngs..add(z.centerLng - dr)..add(z.centerLng + dr);
    }
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);
    return _Bounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return AppColors.red;
      case 'high':
        return AppColors.orange;
      case 'medium':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  @override
  bool shouldRepaint(covariant _ResponseMapPainter old) {
    return old.dispatches != dispatches ||
        old.closures != closures ||
        old.zones != zones ||
        old.event != event;
  }
}

class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
  double get spanLat => math.max(0.001, maxLat - minLat);
  double get spanLng => math.max(0.001, maxLng - minLng);
}
