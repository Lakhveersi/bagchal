import 'package:flutter/material.dart';

import '../models/board_config.dart';
import '../models/piece.dart';

class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.points, required this.connections, required this.positionOf, this.selected, this.highlightTargets = const {}});

  final Iterable<Point> points;
  final List<Connection> connections;
  final Offset Function(Point) positionOf; // normalized 0..1
  final Point? selected;
  final Set<Point> highlightTargets;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          return CustomPaint(
            size: Size.square(size),
            painter: _BoardPainter(
              points: points,
              connections: connections,
              positionOf: positionOf,
              selected: selected,
              highlightTargets: highlightTargets,
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.points, required this.connections, required this.positionOf, required this.selected, required this.highlightTargets});

  final Iterable<Point> points;
  final List<Connection> connections;
  final Offset Function(Point) positionOf;
  final Point? selected;
  final Set<Point> highlightTargets;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;
    final goatPaint = Paint()..color = const Color(0xFF4ECDC4);
    final tigerPaint = Paint()..color = const Color(0xFFFFD700);
    final emptyPaint = Paint()..color = Colors.white70;
    final highlightPaint = Paint()..color = Colors.orangeAccent.withOpacity(0.6);

    // background
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), bgPaint);

    // draw connections
    for (final c in connections) {
      final p1 = positionOf(c.from);
      final p2 = positionOf(c.to);
      final o1 = Offset(p1.dx * size.width, p1.dy * size.height);
      final o2 = Offset(p2.dx * size.width, p2.dy * size.height);
      canvas.drawLine(o1, o2, linePaint);
    }

    const double nodeRadius = 10;
    for (final p in points) {
      final pos = positionOf(p);
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final isSelected = selected != null && selected == p;
      final isHighlight = highlightTargets.contains(p);

      final paint = p.type == PieceType.goat
          ? goatPaint
          : p.type == PieceType.tiger
              ? tigerPaint
              : emptyPaint;
      canvas.drawCircle(center, nodeRadius + (isSelected ? 4 : 0), paint);
      if (isHighlight) {
        canvas.drawCircle(center, nodeRadius + 8, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.connections != connections ||
        oldDelegate.selected != selected ||
        oldDelegate.highlightTargets != highlightTargets;
  }
}

