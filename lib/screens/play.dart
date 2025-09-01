import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_controller.dart';
import '../widgets/board.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(builder: (context, g, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Turn: ${g.currentTurn.name}'),
          actions: [
            IconButton(
              onPressed: () => g.resetGame(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: Center(child: const BoardWidget())),
            if (g.gameMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(g.gameMessage!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }
}

