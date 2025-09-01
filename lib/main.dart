import 'package:flutter/material.dart';
import 'constants.dart';
import 'controllers/game_controller.dart';
import 'controllers/ai_controller.dart';
import 'models/ampul_board_config.dart';
import 'models/board_config.dart';
import 'models/piece.dart';
import 'widgets/board_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bagh-Chal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.nebulaTeal),
        scaffoldBackgroundColor: AppColors.deepSpace,
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String mode = 'PVC';
  String side = 'Goat';
  Difficulty difficulty = Difficulty.medium;
  BoardType board = BoardType.square;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagh-Chal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Mode'),
            Wrap(spacing: 8, children: [
              _chip('PVC', mode == 'PVC', () => setState(() => mode = 'PVC')),
              _chip('PVP', mode == 'PVP', () => setState(() => mode = 'PVP')),
            ]),
            const SizedBox(height: 12),
            _sectionTitle('Side'),
            Wrap(spacing: 8, children: [
              _chip('Goat', side == 'Goat', () => setState(() => side = 'Goat')),
              _chip('Tiger', side == 'Tiger', () => setState(() => side = 'Tiger')),
            ]),
            const SizedBox(height: 12),
            _sectionTitle('Difficulty'),
            Wrap(spacing: 8, children: [
              _chip('Easy', difficulty == Difficulty.easy, () => setState(() => difficulty = Difficulty.easy)),
              _chip('Medium', difficulty == Difficulty.medium, () => setState(() => difficulty = Difficulty.medium)),
              _chip('Hard', difficulty == Difficulty.hard, () => setState(() => difficulty = Difficulty.hard)),
            ]),
            const SizedBox(height: 12),
            _sectionTitle('Board'),
            Wrap(spacing: 8, children: [
              _chip('Square', board == BoardType.square, () => setState(() => board = BoardType.square)),
              _chip('Ampul', board == BoardType.aaduPuli, () => setState(() => board = BoardType.aaduPuli)),
            ]),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GameScreen(
                      boardType: board,
                      mode: mode,
                      side: side,
                      difficulty: difficulty,
                    ),
                  ));
                },
                child: const Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _chip(String label, bool selected, VoidCallback onSelected) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.boardType, required this.mode, required this.side, required this.difficulty});

  final BoardType boardType;
  final String mode; // PVC or PVP
  final String side; // Goat or Tiger
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController controller;
  AiController? ai;

  @override
  void initState() {
    super.initState();
    controller = GameController(boardType: widget.boardType);
    controller.addListener(() => setState(() {}));
    ai = AiController(controller);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAiTurn());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.boardType == BoardType.square ? 'Square' : 'Ampul'} • ${controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger'} Turn'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _buildBoard(),
            ),
            const SizedBox(height: 12),
            Text('Goats placed: ${controller.goatsPlaced}  •  Captured: ${controller.goatsCaptured}')
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    if (widget.boardType == BoardType.square) {
      final board = controller.squareBoard!;
      final points = board.expand((e) => e);
      final connections = <Connection>[];
      final had = <String>{};
      for (final p in points) {
        for (final q in p.adjacentPoints) {
          final key = '${p.hashCode}-${q.hashCode}';
          final rkey = '${q.hashCode}-${p.hashCode}';
          if (had.contains(key) || had.contains(rkey)) continue;
          had.add(key);
          connections.add(Connection(p, q));
        }
      }
      Offset pos(Point p) => Offset((p.x) / 4, (p.y) / 4);
      return BoardView(points: points, connections: connections, positionOf: pos);
    } else {
      final config = controller.ampulBoard ?? AmpulBoardFactory.create();
      Offset pos(Point p) => p.position ?? const Offset(0.5, 0.5);
      return GestureDetector(
        onTapUp: (d) {
          _handleTap(d.localPosition, context.size);
        },
        child: BoardView(points: config.nodes, connections: config.connections, positionOf: pos),
      );
    }
  }

  void _handleTap(Offset local, Size? size) {
    size ??= const Size(1, 1);
    // hit test nearest node within radius
    final points = widget.boardType == BoardType.square
        ? controller.squareBoard!.expand((e) => e)
        : controller.ampulBoard!.nodes;
    Point? nearest;
    double best = 1e9;
    for (final p in points) {
      final pos = widget.boardType == BoardType.square ? Offset(p.x / 4, p.y / 4) : (p.position ?? const Offset(0.5, 0.5));
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final d = (center - local).distance;
      if (d < best) {
        best = d;
        nearest = p;
      }
    }
    if (nearest == null) return;
    if (best > 28) return; // tap threshold

    // Placement if it's goat turn and still placing
    if (controller.currentTurn == PieceType.goat && controller.isGoatPlacementPhase) {
      final placed = controller.placeGoat(nearest);
      if (placed) _maybeAiTurn();
      return;
    }
    // Otherwise, attempt to move: first tap selects; second tap moves
    setState(() {
      _selected ??= null;
      if (_selected == null) {
        if (nearest!.type == controller.currentTurn) {
          _selected = nearest;
        }
      } else {
        final from = _selected!;
        final ok = controller.move(from, nearest!);
        _selected = null;
        if (ok) _maybeAiTurn();
      }
    });
  }

  Point? _selected;

  Future<void> _maybeAiTurn() async {
    await ai?.maybePlayAiTurnIfNeeded(mode: widget.mode, side: widget.side, difficulty: widget.difficulty);
  }
}
