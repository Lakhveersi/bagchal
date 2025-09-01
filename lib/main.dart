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
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.space),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Bagh-Chal', style: AppTextStyles.title(context)),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final settingsPanel = Container(
              decoration: AppDecorations.panel,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Text('Mode', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('PVC', mode == 'PVC', () => setState(() => mode = 'PVC')),
                    _chip('PVP', mode == 'PVP', () => setState(() => mode = 'PVP')),
                  ]),
                  const SizedBox(height: 16),
                  Text('Side', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Goat', side == 'Goat', () => setState(() => side = 'Goat')),
                    _chip('Tiger', side == 'Tiger', () => setState(() => side = 'Tiger')),
                  ]),
                  const SizedBox(height: 16),
                  Text('Difficulty', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Easy', difficulty == Difficulty.easy, () => setState(() => difficulty = Difficulty.easy)),
                    _chip('Medium', difficulty == Difficulty.medium, () => setState(() => difficulty = Difficulty.medium)),
                    _chip('Hard', difficulty == Difficulty.hard, () => setState(() => difficulty = Difficulty.hard)),
                  ]),
                  const SizedBox(height: 16),
                  Text('Board', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Square', board == BoardType.square, () => setState(() => board = BoardType.square)),
                    _chip('Ampul', board == BoardType.aaduPuli, () => setState(() => board = BoardType.aaduPuli)),
                  ]),
                  if (isWide) const Spacer() else const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.stellarGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(children: [Expanded(child: settingsPanel)])
                  : SingleChildScrollView(child: settingsPanel),
            );
          },
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
        title: Text(_appBarTitle()),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () {
              controller.reset();
              _clearSelection();
              WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAiTurn());
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTurnIndicator(),
            const SizedBox(height: 8),
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

  String _appBarTitle() {
    final boardName = widget.boardType == BoardType.square ? 'Square' : 'Ampul';
    final current = controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger';
    final isPVC = widget.mode == 'PVC';
    final isPlayerTurn = !isPVC || (widget.side == current);
    final who = isPlayerTurn ? 'Your Turn' : 'Computer Turn';
    return '$boardName • $who ($current)';
  }

  Widget _buildTurnIndicator() {
    final isPVC = widget.mode == 'PVC';
    final current = controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger';
    final isPlayerTurn = !isPVC || (widget.side == current);
    final color = isPlayerTurn ? Colors.greenAccent : Colors.orangeAccent;
    final label = isPlayerTurn ? 'Your Turn' : 'Computer Turn';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label • $current', style: TextStyle(color: color)),
      ),
    );
  }

  Widget _buildBoard() {
    final bool isSquare = widget.boardType == BoardType.square;
    final Iterable<Point> points;
    final List<Connection> connections = <Connection>[];
    Offset Function(Point) positionOf;

    if (isSquare) {
      final board = controller.squareBoard!;
      points = board.expand((e) => e);
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
      positionOf = (Point p) => Offset((p.x) / 4, (p.y) / 4);
    } else {
      final config = controller.ampulBoard ?? AmpulBoardFactory.create();
      points = config.nodes;
      connections.addAll(config.connections);
      positionOf = (Point p) => p.position ?? const Offset(0.5, 0.5);
    }

    return BoardView(
      points: points,
      connections: connections,
      positionOf: positionOf,
      selected: _selected,
      highlightTargets: _highlightTargets,
      onTapUp: (local, size) => _handleTap(local, size),
    );
  }

  void _handleTap(Offset local, Size? size) {
    size ??= const Size(1, 1);
    // Prevent user interaction during AI's turn in PVC mode
    if (widget.mode == 'PVC') {
      final currentSide = controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger';
      if (widget.side != currentSide) return;
    }
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
      if (placed) {
        _clearSelection();
        _maybeHandleGameEndAndAi();
      }
      return;
    }
    // Otherwise, attempt to move: first tap selects; second tap moves
    setState(() {
      if (_selected == null) {
        if (nearest!.type == controller.currentTurn) {
          _selected = nearest;
          _highlightTargets = controller.validMoves(_selected!).toSet();
        } else {
          _clearSelection();
        }
      } else {
        final from = _selected!;
        final ok = controller.move(from, nearest!);
        _clearSelection();
        if (ok) {
          _maybeHandleGameEndAndAi();
        }
      }
    });
  }

  Point? _selected;
  Set<Point> _highlightTargets = <Point>{};

  void _clearSelection() {
    _selected = null;
    _highlightTargets = <Point>{};
  }

  Future<void> _maybeAiTurn() async {
    await ai?.maybePlayAiTurnIfNeeded(mode: widget.mode, side: widget.side, difficulty: widget.difficulty);
  }

  Future<void> _maybeHandleGameEndAndAi() async {
    // Show win/lose if reached
    if (controller.isTigerWin || controller.isGoatWin) {
      final winner = controller.isTigerWin ? 'Tiger' : 'Goat';
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$winner wins!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
      return;
    }
    await _maybeAiTurn();
  }
}
