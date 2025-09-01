import 'dart:async';
import 'dart:math';

import '../constants.dart';
import '../controllers/game_controller.dart';
import '../logic/aadu_puli_logic.dart' as ampul;
import '../models/piece.dart';

class AiController {
  AiController(this.gameController) : _rng = Random();

  final GameController gameController;
  final Random _rng;
  bool _busy = false;

  Future<void> maybePlayAiTurnIfNeeded({required String mode, required String side, required Difficulty difficulty}) async {
    if (mode != 'PVC') return;
    final isAiGoat = side == 'Tiger';
    final isAiTiger = side == 'Goat';
    if (!isAiGoat && !isAiTiger) return;

    if (_busy) return;
    if (isAiGoat && gameController.currentTurn != PieceType.goat) return;
    if (isAiTiger && gameController.currentTurn != PieceType.tiger) return;

    _busy = true;
    try {
      // small delay for UX
      await Future.delayed(const Duration(milliseconds: 300));
      switch (difficulty) {
        case Difficulty.easy:
          await _playEasy();
          break;
        case Difficulty.medium:
          await _playEasy();
          break;
        case Difficulty.hard:
          await _playEasy();
          break;
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _playEasy() async {
    if (gameController.currentTurn == PieceType.goat) {
      await _goatEasy();
    } else {
      await _tigerEasy();
    }
  }

  Future<void> _goatEasy() async {
    // Placement phase: place randomly, try to avoid immediate capture if possible
    if (gameController.isGoatPlacementPhase) {
      final empties = _allPoints().where((p) => p.type == PieceType.empty).toList();
      if (empties.isEmpty) return;
      // Try safe first
      final safe = empties.where(_isPlacementRelativelySafe).toList();
      final target = (safe.isNotEmpty ? safe : empties)[_rng.nextInt((safe.isNotEmpty ? safe : empties).length)];
      gameController.placeGoat(target);
      return;
    }
    // Move phase: collect all goat moves
    final moves = <_Move>[];
    for (final p in _allPoints()) {
      if (p.type != PieceType.goat) continue;
      final valids = gameController.validMoves(p);
      for (final to in valids) {
        moves.add(_Move(from: p, to: to, isCapture: false));
      }
    }
    if (moves.isEmpty) return;
    final choice = moves[_rng.nextInt(moves.length)];
    gameController.move(choice.from, choice.to);
  }

  Future<void> _tigerEasy() async {
    // Prefer captures if available
    final capturing = <_Move>[];
    final regular = <_Move>[];
    for (final p in _allPoints()) {
      if (p.type != PieceType.tiger) continue;
      final valids = gameController.validMoves(p);
      for (final to in valids) {
        final isCapture = _isCaptureMove(p, to);
        (isCapture ? capturing : regular).add(_Move(from: p, to: to, isCapture: isCapture));
      }
    }
    final pool = capturing.isNotEmpty ? capturing : regular;
    if (pool.isEmpty) return;
    final choice = pool[_rng.nextInt(pool.length)];
    gameController.move(choice.from, choice.to);
  }

  bool _isPlacementRelativelySafe(Point target) {
    // A simple heuristic: avoid direct jump capture if immediately possible by any adjacent tiger
    // Only implemented for Ampul using adjacency + jump triple; for Square we approximate by checking 2-step availability
    if (target.type != PieceType.empty) return false;
    // Temporarily consider a goat at target and see if any tiger can jump over it
    for (final tiger in _allPoints().where((p) => p.type == PieceType.tiger)) {
      // If tiger is adjacent to target, check if there exists a landing that forms a valid jump
      if (!tiger.adjacentPoints.contains(target)) continue;
      for (final landing in target.adjacentPoints) {
        if (landing == tiger || landing.type != PieceType.empty) continue;
        if (gameController.ampulBoard != null) {
          final key = '${tiger.id},${target.id},${landing.id}';
          if (ampul.AaduPuliLogic.isJumpTriple(key)) return false;
        } else {
          // Square: landing must be two steps in the same vector and empty; also ensure adjacency graph allows it
          final dx = landing.x - tiger.x;
          final dy = landing.y - tiger.y;
          if ((dx.abs() == 2 || dy.abs() == 2) && tiger.adjacentPoints.contains(target) && target.adjacentPoints.contains(landing)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _isCaptureMove(Point from, Point to) {
    // Square: distance 2 move
    if (gameController.squareBoard != null) {
      final dx = (to.x - from.x).abs();
      final dy = (to.y - from.y).abs();
      return dx == 2 || dy == 2;
    }
    // Ampul: non-adjacent move for tiger
    return !from.adjacentPoints.contains(to);
  }

  Iterable<Point> _allPoints() {
    if (gameController.squareBoard != null) {
      return gameController.squareBoard!.expand((r) => r);
    }
    return gameController.ampulBoard!.nodes;
  }
}

class _Move {
  _Move({required this.from, required this.to, required this.isCapture});
  final Point from;
  final Point to;
  final bool isCapture;
}

