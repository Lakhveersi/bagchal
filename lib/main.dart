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

            Widget panel = Container(
              decoration: AppDecorations.panel,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 20),
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
                  ? Row(children: [Expanded(child: panel)])
                  : SingleChildScrollView(child: panel),
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
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.jungle),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '${widget.boardType == BoardType.square ? 'Square' : 'Ampul'} • ${controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger'} Turn',
            style: AppTextStyles.title(context),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final boardWidget = Container(
                decoration: AppDecorations.board,
                padding: const EdgeInsets.all(12),
                child: _buildBoard(),
              );
              final infoPanel = Container(
                decoration: AppDecorations.panel,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stats', style: AppTextStyles.subtitle(context)),
                    const SizedBox(height: 8),
                    _statBadge(context, 'Placed', controller.goatsPlaced.toString()),
                    const SizedBox(height: 8),
                    _statBadge(context, 'Captured', controller.goatsCaptured.toString()),
                    const SizedBox(height: 8),
                    _statBadge(context, 'Turn', controller.currentTurn == PieceType.goat ? 'Goat' : 'Tiger'),
                  ],
                ),
              );
              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: boardWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: infoPanel),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: boardWidget),
                  const SizedBox(height: 16),
                  infoPanel,
                ],
              );
            },
          ),
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
      final highlights = _selected == null
          ? <Point>{}
          : controller.validMoves(_selected!).toSet();
      return BoardView(
        points: points,
        connections: connections,
        positionOf: pos,
        selected: _selected,
        highlightTargets: highlights,
        onTapUp: _handleTap,
      );
    } else {
      final config = controller.ampulBoard ?? AmpulBoardFactory.create();
      Offset pos(Point p) => p.position ?? const Offset(0.5, 0.5);
      final highlights = _selected == null
          ? <Point>{}
          : controller.validMoves(_selected!).toSet();
      return BoardView(
        points: config.nodes,
        connections: config.connections,
        positionOf: pos,
        selected: _selected,
        highlightTargets: highlights,
        onTapUp: _handleTap,
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
      if (placed) {
        _maybeAiTurn();
        _maybeShowWin();
      }
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
        if (ok) {
          _maybeAiTurn();
          _maybeShowWin();
        }
      }
    });
  }

  Point? _selected;

  Future<void> _maybeAiTurn() async {
    await ai?.maybePlayAiTurnIfNeeded(mode: widget.mode, side: widget.side, difficulty: widget.difficulty);
  }

  void _maybeShowWin() {
    if (controller.isTigerWin || controller.isGoatWin) {
      final message = controller.isTigerWin ? 'Tigers Win!' : 'Goats Win!';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cosmicBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24),
          ),
          title: Text('Game Over', style: AppTextStyles.title(context)),
          content: Text(message, style: AppTextStyles.subtitle(context)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Main Menu'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.reset();
                Navigator.of(context).pop();
              },
              child: const Text('New Game'),
            ),
          ],
        ),
      );
    }
  }

  Widget _statBadge(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTextStyles.body(context).copyWith(color: Colors.white70)),
          Text(value, style: AppTextStyles.badge(context)),
        ],
      ),
    );
  }
}
