import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_controller.dart';
import '../models/piece.dart';
import '../constants.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(builder: (context, g, _) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: CustomPaint(
            painter: g.boardType == BoardType.square ? _SquarePainter() : _AmpulPainter(g),
            child: Stack(children: _buildPieces(context, g)),
          ),
        ),
      );
    });
  }

  List<Widget> _buildPieces(BuildContext context, GameController g) {
    final widgets = <Widget>[];
    if (g.boardType == BoardType.square) {
      const margin = 12.0;
      return [
        for (int x = 0; x < 5; x++)
          for (int y = 0; y < 5; y++)
            Positioned.fill(
              child: LayoutBuilder(builder: (context, c) {
                final cell = (c.maxWidth - 2 * margin) / 4;
                final dx = margin + y * cell;
                final dy = margin + x * cell;
                final p = g.board[x][y];
                return Stack(children: [
                  Positioned(
                    left: dx - 12,
                    top: dy - 12,
                    child: GestureDetector(
                      onTap: () => g.onPointTap(p),
                      child: _piece(p, selected: g.selectedPiece == p, isValid: g.validMoves.contains(p)),
                    ),
                  ),
                ]);
              }),
            ),
      ];
    }
    // Ampul
    const pad = 16.0;
    return [
      for (final p in g.boardConfig!.nodes)
        Positioned.fill(
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth - pad * 2;
            final h = c.maxHeight - pad * 2;
            final dx = pad + (p.position!.dx * w);
            final dy = pad + (p.position!.dy * h);
            return Stack(children: [
              Positioned(
                left: dx - 12,
                top: dy - 12,
                child: GestureDetector(
                  onTap: () => g.onPointTap(p),
                  child: _piece(p, selected: g.selectedPiece == p, isValid: g.validMoves.contains(p)),
                ),
              ),
            ]);
          }),
        ),
    ];
  }

  Widget _piece(Point p, {required bool selected, required bool isValid}) {
    Color color;
    if (p.type == PieceType.tiger) color = Colors.redAccent;
    else if (p.type == PieceType.goat) color = Colors.white;
    else color = Colors.transparent;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isValid)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent, width: 2),
            ),
          ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? Colors.amber : Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _SquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const margin = 12.0;
    final cell = (size.width - 2 * margin) / 4;
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // border
    canvas.drawRect(Rect.fromLTWH(margin, margin, size.width - 2 * margin, size.height - 2 * margin), paint);
    // grid lines
    for (int i = 0; i < 5; i++) {
      final y = margin + i * cell;
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
      final x = margin + i * cell;
      canvas.drawLine(Offset(x, margin), Offset(x, size.height - margin), paint);
    }
    // diagonals on alternating cells
    for (int x = 0; x < 5; x++) {
      for (int y = 0; y < 5; y++) {
        if (x > 0 && y > 0 && (x % 2 == y % 2)) {
          final cx = margin + y * cell;
          final cy = margin + x * cell;
          canvas.drawLine(Offset(cx, cy), Offset(cx - cell, cy - cell), paint);
          canvas.drawLine(Offset(cx, cy), Offset(cx + cell, cy - cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AmpulPainter extends CustomPainter {
  final GameController g;
  _AmpulPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 16.0;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    final p = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final c in g.boardConfig!.connections) {
      final a = Offset(pad + c.from.position!.dx * w, pad + c.from.position!.dy * h);
      final b = Offset(pad + c.to.position!.dx * w, pad + c.to.position!.dy * h);
      canvas.drawLine(a, b, p);
    }

    final nodePaint = Paint()..color = Colors.amber;
    for (final n in g.boardConfig!.nodes) {
      final o = Offset(pad + n.position!.dx * w, pad + n.position!.dy * h);
      canvas.drawCircle(o, 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

