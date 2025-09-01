import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_controller.dart';
import '../constants.dart';
import 'play.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagh-Chal')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<GameController>().setGameMode(
                      GameMode.pvc,
                      side: PlayerSide.goat,
                      diff: Difficulty.hard,
                    );
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayScreen()));
              },
              child: const Text('PVC (You = Goat vs AI Tiger)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<GameController>().setGameMode(
                      GameMode.pvp,
                    );
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayScreen()));
              },
              child: const Text('PVP'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<GameController>().setBoardType(BoardType.square);
                  },
                  child: const Text('Square'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<GameController>().setBoardType(BoardType.aaduPuli);
                  },
                  child: const Text('Ampul'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

