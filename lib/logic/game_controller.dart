import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/piece.dart';
import '../models/board_config.dart';
import 'square_board_logic.dart' as square;
import 'aadu_puli_logic.dart' as aadu;
import '../utils/board_utils.dart';

enum PlayerType { human, computer }
enum GameMode { pvp, pvc }
enum PlayerSide { tiger, goat }

class GameController extends ChangeNotifier {
  // Board state
  List<List<Point>> board = [];
  BoardConfig? boardConfig;

  // Game state
  int placedGoats = 0;
  int capturedGoats = 0;
  bool isGoatMovementPhase = false;
  PieceType currentTurn = PieceType.goat;
  Point? selectedPiece;
  List<Point> validMoves = [];
  String? gameMessage;

  // Settings
  GameMode gameMode = GameMode.pvp;
  BoardType boardType = BoardType.square;
  Difficulty difficulty = Difficulty.easy;
  PlayerSide playerSide = PlayerSide.tiger;
  PlayerType tigerPlayer = PlayerType.human;
  PlayerType goatPlayer = PlayerType.human;

  // Timers
  Timer? _aiTimer;
  bool isPaused = false;

  GameController() {
    resetGame();
  }

  int get maxGoats => boardType == BoardType.square ? 20 : aadu.AaduPuliLogic.maxGoats;
  int get requiredCaptures => boardType == BoardType.square ? 5 : aadu.AaduPuliLogic.requiredCaptures;

  void setBoardType(BoardType type) {
    boardType = type;
    resetGame();
  }

  void setGameMode(
    GameMode mode, {
    PlayerSide? side,
    Difficulty? diff,
  }) {
    gameMode = mode;
    playerSide = side ?? playerSide;
    difficulty = diff ?? difficulty;
    if (gameMode == GameMode.pvc) {
      if (playerSide == PlayerSide.tiger) {
        tigerPlayer = PlayerType.human;
        goatPlayer = PlayerType.computer;
      } else {
        tigerPlayer = PlayerType.computer;
        goatPlayer = PlayerType.human;
      }
    } else {
      tigerPlayer = PlayerType.human;
      goatPlayer = PlayerType.human;
    }
    notifyListeners();
  }

  void resetGame() {
    _cancelAiTimer();
    if (boardType == BoardType.square) {
      board = square.SquareBoardLogic.initializeBoard();
      boardConfig = null;
    } else {
      board = [];
      boardConfig = BoardUtils.getAaduPuliConfig();
      aadu.AaduPuliLogic.initializeBoard(boardConfig!);
    }
    placedGoats = 0;
    capturedGoats = 0;
    isGoatMovementPhase = false;
    currentTurn = PieceType.goat;
    selectedPiece = null;
    validMoves = [];
    gameMessage = null;
    notifyListeners();
    _maybeScheduleAi();
  }

  // ========= Turn helpers =========
  bool _isHumanTurn() {
    if (gameMode == GameMode.pvp) return true;
    if (currentTurn == PieceType.tiger) return tigerPlayer == PlayerType.human;
    return goatPlayer == PlayerType.human;
  }

  bool _isComputerTurn() {
    if (gameMode != GameMode.pvc) return false;
    if (currentTurn == PieceType.tiger) return tigerPlayer == PlayerType.computer;
    return goatPlayer == PlayerType.computer;
  }

  void _maybeScheduleAi() {
    if (_isComputerTurn() && gameMessage == null && !isPaused) {
      _cancelAiTimer();
      _aiTimer = Timer(const Duration(milliseconds: 450), makeComputerMove);
    }
  }

  void _cancelAiTimer() {
    _aiTimer?.cancel();
    _aiTimer = null;
  }

  // ========= Input =========
  void onPointTap(Point point) {
    if (gameMessage != null || isPaused) return;
    if (!_isHumanTurn()) return;

    if (!isGoatMovementPhase && currentTurn == PieceType.goat) {
      _placeGoat(point);
    } else {
      _handleMovement(point);
    }
    _checkWin();
    _maybeScheduleAi();
  }

  // ========= AI =========
  void makeComputerMove() {
    if (!_isComputerTurn() || gameMessage != null || isPaused) return;

    if (currentTurn == PieceType.tiger) {
      _makeTigerAIMove();
    } else {
      _makeGoatAIMove();
    }

    _checkWin();
    // Important: do NOT loop here; only schedule again if still AI turn
    _maybeScheduleAi();
  }

  void _makeTigerAIMove() {
    final moves = _collectMovesFor(PieceType.tiger);
    if (moves.isEmpty) return;
    final chosen = _selectMoveTiger(moves);
    _executeMove(chosen['from']!, chosen['to']!);
  }

  void _makeGoatAIMove() {
    if (!isGoatMovementPhase) {
      // Placement phase
      final empties = _emptyPoints();
      if (empties.isEmpty) return;
      Point choice;
      switch (difficulty) {
        case Difficulty.easy:
          choice = empties[Random().nextInt(empties.length)];
          break;
        case Difficulty.medium:
          choice = _chooseSafePlacement(empties) ?? empties[Random().nextInt(empties.length)];
          break;
        case Difficulty.hard:
          choice = _bestHeuristicPlacement(empties) ?? _chooseSafePlacement(empties) ?? empties[Random().nextInt(empties.length)];
          break;
      }
      _placeGoat(choice);
      return;
    }

    // Movement phase
    final moves = _collectMovesFor(PieceType.goat);
    if (moves.isEmpty) return;
    Map<String, Point> chosen;
    switch (difficulty) {
      case Difficulty.easy:
        chosen = moves[Random().nextInt(moves.length)];
        break;
      case Difficulty.medium:
        chosen = _preferBlockingMove(moves) ?? moves[Random().nextInt(moves.length)];
        break;
      case Difficulty.hard:
        chosen = _minimaxMove(moves, depth: 2, maximizingForTiger: false);
        break;
    }
    _executeMove(chosen['from']!, chosen['to']!);
  }

  List<Map<String, Point>> _collectMovesFor(PieceType side) {
    final list = <Map<String, Point>>[];
    if (boardType == BoardType.square) {
      for (final p in board.expand((r) => r).where((p) => p.type == side)) {
        for (final to in square.SquareBoardLogic.getValidMoves(p, board)) {
          list.add({'from': p, 'to': to});
        }
      }
    } else if (boardConfig != null) {
      for (final p in boardConfig!.nodes.where((n) => n.type == side)) {
        for (final to in aadu.AaduPuliLogic.getValidMoves(p, boardConfig!)) {
          list.add({'from': p, 'to': to});
        }
      }
    }
    return list;
  }

  Map<String, Point> _selectMoveTiger(List<Map<String, Point>> moves) {
    switch (difficulty) {
      case Difficulty.easy:
        // Prefer captures randomly
        final captures = moves.where((m) => !_areAdjacent(m['from']!, m['to']!)).toList();
        if (captures.isNotEmpty) return captures[Random().nextInt(captures.length)];
        return moves[Random().nextInt(moves.length)];
      case Difficulty.medium:
        // Always take a capture if available; else random
        final captures = moves.where((m) => !_areAdjacent(m['from']!, m['to']!)).toList();
        if (captures.isNotEmpty) return captures[Random().nextInt(captures.length)];
        return moves[Random().nextInt(moves.length)];
      case Difficulty.hard:
        return _minimaxMove(moves, depth: 2, maximizingForTiger: true);
    }
  }

  Map<String, Point> _minimaxMove(
    List<Map<String, Point>> moves, {
    required int depth,
    required bool maximizingForTiger,
  }) {
    Map<String, Point>? best;
    double bestVal = maximizingForTiger ? -1e9 : 1e9;
    for (final m in moves) {
      final eval = _evaluateAfterMove(m['from']!, m['to']!, depth, maximizingForTiger);
      if (maximizingForTiger) {
        if (eval > bestVal) {
          bestVal = eval;
          best = m;
        }
      } else {
        if (eval < bestVal) {
          bestVal = eval;
          best = m;
        }
      }
    }
    return best ?? moves.first;
  }

  double _evaluateAfterMove(Point from, Point to, int depth, bool maximizingForTiger) {
    // Clone
    final b = boardType == BoardType.square ? _cloneSquare(board) : null;
    final cfg = boardType == BoardType.aaduPuli && boardConfig != null ? _cloneConfig(boardConfig!) : null;
    int cap = capturedGoats;
    if (boardType == BoardType.square && b != null) {
      final res = square.SquareBoardLogic.executeMove(b[from.x][from.y], b[to.x][to.y], b);
      if (res == square.MoveResult.capture) cap++;
    } else if (cfg != null) {
      final f = cfg.nodes.firstWhere((n) => n.id == from.id);
      final t = cfg.nodes.firstWhere((n) => n.id == to.id);
      final res = aadu.AaduPuliLogic.executeMove(f, t, cfg);
      if (res == aadu.MoveResult.capture) cap++;
    }
    if (depth == 0) {
      return _evaluateState(b, cfg, cap, maximizingForTiger);
    }

    // Next side
    final nextSide = (from.type == PieceType.tiger) ? PieceType.goat : PieceType.tiger;
    final nextMoves = <Map<String, Point>>[];
    if (b != null) {
      for (final p in b.expand((r) => r).where((p) => p.type == nextSide)) {
        for (final dest in square.SquareBoardLogic.getValidMoves(p, b)) {
          nextMoves.add({'from': p, 'to': dest});
        }
      }
    } else if (cfg != null) {
      for (final p in cfg.nodes.where((n) => n.type == nextSide)) {
        for (final dest in aadu.AaduPuliLogic.getValidMoves(p, cfg)) {
          nextMoves.add({'from': p, 'to': dest});
        }
      }
    }
    if (nextMoves.isEmpty) return _evaluateState(b, cfg, cap, maximizingForTiger);
    final childVals = nextMoves.map((m) {
      return _evaluateAfterMove(m['from']!, m['to']!, depth - 1, maximizingForTiger);
    }).toList();
    return (from.type == PieceType.tiger) ? childVals.reduce(min) : childVals.reduce(max);
  }

  double _evaluateState(List<List<Point>>? b, BoardConfig? cfg, int cap, bool maximizingForTiger) {
    int tigerMobility = 0;
    int blockedTigers = 0;
    int unsafeGoats = 0;
    if (b != null) {
      final tigers = b.expand((r) => r).where((p) => p.type == PieceType.tiger);
      for (final t in tigers) {
        final m = square.SquareBoardLogic.getValidMoves(t, b);
        tigerMobility += m.length;
        if (m.isEmpty) blockedTigers++;
      }
      unsafeGoats = _countUnsafeGoatsOn(b);
    } else if (cfg != null) {
      final tigers = cfg.nodes.where((n) => n.type == PieceType.tiger);
      for (final t in tigers) {
        final m = aadu.AaduPuliLogic.getValidMoves(t, cfg);
        tigerMobility += m.length;
        if (m.isEmpty) blockedTigers++;
      }
      // Rough proxy
      unsafeGoats = cfg.nodes.where((n) => n.type == PieceType.goat && n.adjacentPoints.any((a) => a.type == PieceType.tiger)).length;
    }
    if (maximizingForTiger) {
      return 20.0 * cap - 5.0 * blockedTigers + 1.0 * tigerMobility;
    }
    return -15.0 * cap + 8.0 * blockedTigers - 1.0 * tigerMobility - 2.0 * unsafeGoats;
  }

  // ========= Placement & movement =========
  void _placeGoat(Point point) {
    if (point.type != PieceType.empty || placedGoats >= maxGoats) return;
    point.type = PieceType.goat;
    placedGoats++;
    if (placedGoats >= maxGoats) {
      isGoatMovementPhase = true;
    }
    _switchTurn();
    notifyListeners();
  }

  void _handleMovement(Point point) {
    if (selectedPiece == null) {
      if (point.type == currentTurn) {
        selectedPiece = point;
        validMoves = _getValidMoves(point);
      }
      notifyListeners();
      return;
    }
    if (validMoves.contains(point)) {
      _executeMove(selectedPiece!, point);
    }
    selectedPiece = null;
    validMoves = [];
    notifyListeners();
  }

  List<Point> _getValidMoves(Point piece) {
    if (boardType == BoardType.square) {
      return square.SquareBoardLogic.getValidMoves(piece, board);
    }
    return aadu.AaduPuliLogic.getValidMoves(piece, boardConfig!);
  }

  void _executeMove(Point from, Point to) {
    if (boardType == BoardType.square) {
      final res = square.SquareBoardLogic.executeMove(from, to, board);
      if (res == square.MoveResult.capture) capturedGoats++;
    } else {
      final res = aadu.AaduPuliLogic.executeMove(from, to, boardConfig!);
      if (res == aadu.MoveResult.capture) capturedGoats++;
    }
    _switchTurn();
    notifyListeners();
  }

  void _switchTurn() {
    if (currentTurn == PieceType.tiger) {
      currentTurn = PieceType.goat;
    } else {
      currentTurn = PieceType.tiger;
    }
  }

  // ========= Win checks =========
  void _checkWin() {
    if (boardType == BoardType.square) {
      if (square.SquareBoardLogic.checkTigerWin(capturedGoats)) {
        gameMessage = 'Tigers win!';
      } else if (square.SquareBoardLogic.checkGoatWin(board)) {
        gameMessage = 'Goats win!';
      }
    } else if (boardConfig != null) {
      if (aadu.AaduPuliLogic.checkTigerWin(capturedGoats)) {
        gameMessage = 'Tigers win!';
      } else if (aadu.AaduPuliLogic.checkGoatWin(boardConfig!)) {
        gameMessage = 'Goats win!';
      }
    }
    if (gameMessage != null) {
      _cancelAiTimer();
      notifyListeners();
    }
  }

  // ========= Utils =========
  bool _areAdjacent(Point a, Point b) => a.adjacentPoints.contains(b);

  List<Point> _emptyPoints() {
    final empties = <Point>[];
    if (boardType == BoardType.square) {
      for (final p in board.expand((r) => r)) {
        if (p.type == PieceType.empty) empties.add(p);
      }
    } else if (boardConfig != null) {
      for (final p in boardConfig!.nodes) {
        if (p.type == PieceType.empty) empties.add(p);
      }
    }
    return empties;
  }

  Point? _chooseSafePlacement(List<Point> empties) {
    return empties.firstWhere(
      (p) => _isGoatSafeIfPlaced(p),
      orElse: () => empties.first,
    );
  }

  Point? _bestHeuristicPlacement(List<Point> empties) {
    double best = -1e9;
    Point? bestP;
    for (final p in empties) {
      final score = _placementScore(p);
      if (score > best) {
        best = score;
        bestP = p;
      }
    }
    return bestP;
  }

  double _placementScore(Point p) {
    // Prefer edges on square; clusters near other goats; avoid immediate capture
    double s = 0;
    if (boardType == BoardType.square) {
      if (p.x == 0 || p.x == 4 || p.y == 0 || p.y == 4) s += 2;
    }
    s += p.adjacentPoints.where((a) => a.type == PieceType.goat).length * 0.5;
    if (_wouldBeCapturable(p)) s -= 5;
    // Reduce tiger mobility heuristic
    s += _mobilityReductionIfPlaced(p) * 0.25;
    return s;
  }

  bool _isGoatSafeIfPlaced(Point p) => !_wouldBeCapturable(p);

  bool _wouldBeCapturable(Point goatPos) {
    if (boardType == BoardType.square) {
      for (final tiger in board.expand((r) => r).where((p) => p.type == PieceType.tiger)) {
        if ((goatPos.x - tiger.x).abs() <= 1 && (goatPos.y - tiger.y).abs() <= 1) {
          final dx = goatPos.x - tiger.x;
          final dy = goatPos.y - tiger.y;
          final lx = goatPos.x + dx;
          final ly = goatPos.y + dy;
          if (lx >= 0 && lx < 5 && ly >= 0 && ly < 5) {
            final landing = board[lx][ly];
            if (landing.type == PieceType.empty && goatPos.adjacentPoints.contains(landing)) {
              return true;
            }
          }
        }
      }
      return false;
    }
    if (boardConfig == null) return false;
    for (final tiger in boardConfig!.nodes.where((n) => n.type == PieceType.tiger)) {
      if (goatPos.adjacentPoints.contains(tiger)) {
        for (final landing in goatPos.adjacentPoints) {
          if (landing == tiger || landing.type != PieceType.empty) continue;
          final key = '${tiger.id},${goatPos.id},${landing.id}';
          if (aadu.AaduPuliLogic.isJumpTriple(key)) return true;
        }
      }
    }
    return false;
  }

  double _mobilityReductionIfPlaced(Point p) {
    if (boardType == BoardType.square) {
      final b = _cloneSquare(board);
      b[p.x][p.y].type = PieceType.goat;
      final before = _tigerMobility(board);
      final after = _tigerMobility(b);
      return (before - after).toDouble();
    }
    if (boardConfig == null) return 0;
    final cfg = _cloneConfig(boardConfig!);
    final np = cfg.nodes.firstWhere((n) => n.id == p.id);
    np.type = PieceType.goat;
    final before = _tigerMobilityConfig(boardConfig!);
    final after = _tigerMobilityConfig(cfg);
    return (before - after).toDouble();
  }

  int _tigerMobility(List<List<Point>> b) {
    int m = 0;
    for (final t in b.expand((r) => r).where((p) => p.type == PieceType.tiger)) {
      m += square.SquareBoardLogic.getValidMoves(t, b).length;
    }
    return m;
  }

  int _tigerMobilityConfig(BoardConfig cfg) {
    int m = 0;
    for (final t in cfg.nodes.where((n) => n.type == PieceType.tiger)) {
      m += aadu.AaduPuliLogic.getValidMoves(t, cfg).length;
    }
    return m;
  }

  List<List<Point>> _cloneSquare(List<List<Point>> original) {
    final out = List.generate(5, (x) => List.generate(5, (y) {
          final p = original[x][y];
          return Point(x: p.x, y: p.y, type: p.type, adjacentPoints: []);
        }));
    for (int x = 0; x < 5; x++) {
      for (int y = 0; y < 5; y++) {
        out[x][y].adjacentPoints = original[x][y].adjacentPoints.map((a) => out[a.x][a.y]).toList();
      }
    }
    return out;
  }

  BoardConfig _cloneConfig(BoardConfig original) {
    final nodes = original.nodes
        .map((p) => Point(x: p.x, y: p.y, type: p.type, id: p.id, position: p.position, adjacentPoints: []))
        .toList();
    for (int i = 0; i < nodes.length; i++) {
      nodes[i].adjacentPoints = original.nodes[i].adjacentPoints.map((a) {
        final idx = original.nodes.indexOf(a);
        return nodes[idx];
      }).toList();
    }
    return BoardConfig(nodes: nodes, connections: original.connections);
  }

  int _countUnsafeGoatsOn(List<List<Point>> b) {
    int c = 0;
    for (final g in b.expand((r) => r).where((p) => p.type == PieceType.goat)) {
      if (_wouldBeCapturable(g)) c++;
    }
    return c;
  }
}

