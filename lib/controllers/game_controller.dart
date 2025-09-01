import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../logic/aadu_puli_logic.dart' as ampul;
import '../logic/square_board_logic.dart' as square;
import '../models/ampul_board_config.dart';
import '../models/board_config.dart';
import '../models/piece.dart';

class GameController extends ChangeNotifier {
  GameController({required this.boardType}) {
    _initializeBoard();
  }

  final BoardType boardType;

  // Square board state
  List<List<Point>>? _squareBoard;

  // Ampul board state
  BoardConfig? _ampulBoard;

  // Turn and counts
  PieceType _currentTurn = PieceType.goat; // Goats start by placing
  int _goatsPlaced = 0;
  int _goatsCaptured = 0;

  bool get isGoatPlacementPhase => _goatsPlaced < _maxGoats;
  PieceType get currentTurn => _currentTurn;
  int get goatsPlaced => _goatsPlaced;
  int get goatsCaptured => _goatsCaptured;

  List<List<Point>>? get squareBoard => _squareBoard;
  BoardConfig? get ampulBoard => _ampulBoard;

  int get _maxGoats => boardType == BoardType.square ? 20 : 15;
  int get _requiredCaptures => boardType == BoardType.square ? 5 : 7;

  void reset() {
    _goatsPlaced = 0;
    _goatsCaptured = 0;
    _currentTurn = PieceType.goat;
    _initializeBoard();
    notifyListeners();
  }

  void _initializeBoard() {
    if (boardType == BoardType.square) {
      _squareBoard = square.SquareBoardLogic.initializeBoard();
      _ampulBoard = null;
    } else {
      final config = AmpulBoardFactory.create();
      ampul.AaduPuliLogic.initializeBoard(config);
      _ampulBoard = config;
      _squareBoard = null;
    }
  }

  // Placement phase: goats place on empty nodes
  bool placeGoat(Point target) {
    if (_currentTurn != PieceType.goat || !isGoatPlacementPhase) return false;
    if (!_isEmpty(target)) return false;

    target.type = PieceType.goat;
    _goatsPlaced += 1;
    _endTurn();
    return true;
  }

  // Movement: from -> to; returns true if move applied
  bool move(Point from, Point to) {
    if (isGoatPlacementPhase && _currentTurn == PieceType.goat) return false;
    if (from.type != _currentTurn) return false;

    if (boardType == BoardType.square) {
      final board = _squareBoard!;
      final result = square.SquareBoardLogic.executeMove(from, to, board);
      if (result == square.MoveResult.invalid) return false;
      if (result == square.MoveResult.capture) _goatsCaptured += 1;
      _endTurn();
      return true;
    } else {
      final config = _ampulBoard!;
      final result = ampul.AaduPuliLogic.executeMove(from, to, config);
      if (result == ampul.MoveResult.invalid) return false;
      if (result == ampul.MoveResult.capture) _goatsCaptured += 1;
      _endTurn();
      return true;
    }
  }

  List<Point> validMoves(Point from) {
    if (boardType == BoardType.square) {
      return square.SquareBoardLogic.getValidMoves(from, _squareBoard!);
    } else {
      return ampul.AaduPuliLogic.getValidMoves(from, _ampulBoard!);
    }
  }

  bool get isTigerWin {
    return _goatsCaptured >= _requiredCaptures;
  }

  bool get isGoatWin {
    if (boardType == BoardType.square) {
      return square.SquareBoardLogic.checkGoatWin(_squareBoard!);
    } else {
      return ampul.AaduPuliLogic.checkGoatWin(_ampulBoard!);
    }
  }

  // Helpers
  bool _isEmpty(Point p) => p.type == PieceType.empty;

  void _endTurn() {
    _currentTurn = _currentTurn == PieceType.goat ? PieceType.tiger : PieceType.goat;
    notifyListeners();
  }
}

