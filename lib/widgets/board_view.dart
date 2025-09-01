import 'package:flutter/material.dart';

import '../models/board_config.dart';
import '../models/piece.dart';

class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.points,
    required this.connections,
    required this.positionOf,
    this.selected,
    this.highlightTargets = const {},
    this.onTapUp,
  });

  final Iterable<Point> points;
  final List<Connection> connections;
  final Offset Function(Point) positionOf; // normalized 0..1
  final Point? selected;
  final Set<Point> highlightTargets;
  final void Function(Offset localPosition, Size size)? onTapUp;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          final boardSize = Size.square(size);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onTapUp == null
                ? null
                : (details) => onTapUp!(details.localPosition, boardSize),
            child: CustomPaint(
              size: boardSize,
              painter: _BoardPainter(
                points: points,
                connections: connections,
                positionOf: positionOf,
                selected: selected,
                highlightTargets: highlightTargets,
              ),
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
      ..shader = const LinearGradient(
        colors: [Color(0xFF2A2F3D), Color(0xFF232836)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 2;
    final goatPaint = Paint()..color = const Color(0xFF4ECDC4);
    final tigerPaint = Paint()..color = const Color(0xFFFFD700);
    final emptyPaint = Paint()..color = Colors.white60;
    final highlightPaint = Paint()..color = Colors.orangeAccent.withOpacity(0.35);

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
      if (isHighlight) {
        canvas.drawCircle(center, nodeRadius + 9, highlightPaint);
      }
      canvas.drawCircle(center, nodeRadius + (isSelected ? 4 : 0), paint);
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

