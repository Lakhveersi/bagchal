import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'board_config.dart';
import 'piece.dart';

/// Creates the Ampul (Aadu Puli Attam) board configuration with 23 nodes
/// arranged in a triangular layout and connections along valid movement lines.
class AmpulBoardFactory {
  /// Returns a BoardConfig whose nodes have:
  /// - id: "0".."22" (stored in Point.id)
  /// - position: Offset normalized to the unit square (0..1)
  /// - type: empty (tigers will be placed by logic initialization)
  ///
  /// Connections are built bidirectionally along the defined lines.
  static BoardConfig create() {
    final nodes = List<Point>.generate(23, (index) {
      return Point(
        x: index, // not used for geometry in this board
        y: 0,
        id: index.toString(),
        position: _positionForIndex(index),
        type: PieceType.empty,
      );
    });

    final connections = <Connection>[];

    // Lines as defined in logic for adjacency and jump triples
    final List<List<int>> lines = [
      [1, 2, 3, 4, 5, 6],
      [7, 8, 9, 10, 11, 12],
      [13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22],
      [0, 2, 8, 14, 19],
      [1, 7, 13],
      [0, 3, 9, 15, 20],
      [0, 4, 10, 16, 21],
      [0, 5, 11, 17, 22],
      [6, 12, 18],
    ];

    void connect(int a, int b) {
      final from = nodes[a];
      final to = nodes[b];
      if (!from.adjacentPoints.contains(to)) {
        from.adjacentPoints.add(to);
      }
      if (!to.adjacentPoints.contains(from)) {
        to.adjacentPoints.add(from);
      }
      connections.add(Connection(from, to));
    }

    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        connect(line[i], line[i + 1]);
      }
    }

    return BoardConfig(nodes: nodes, connections: connections);
  }

  /// Positions are placed in a triangular layout:
  ///   - Row 0: node 0 at the apex
  ///   - Row 1: nodes 1..6 (6 nodes)
  ///   - Row 2: nodes 7..12 (6 nodes)
  ///   - Row 3: nodes 13..18 (6 nodes)
  ///   - Row 4: nodes 19..22 (4 nodes)
  /// Each row is horizontally spread across the triangle width for a balanced look.
  static Offset _positionForIndex(int index) {
    // Layout parameters
    const double padding = 0.08; // outer margin
    const double usable = 1 - 2 * padding; // width and height inside padding

    // Row and column mapping based on canonical indexing used in logic
    int row;
    int colInRow;
    int rowCount;
    if (index == 0) {
      row = 0;
      colInRow = 0;
      rowCount = 1;
    } else if (index >= 1 && index <= 6) {
      row = 1;
      rowCount = 6;
      colInRow = index - 1;
    } else if (index >= 7 && index <= 12) {
      row = 2;
      rowCount = 6;
      colInRow = index - 7;
    } else if (index >= 13 && index <= 18) {
      row = 3;
      rowCount = 6;
      colInRow = index - 13;
    } else {
      row = 4;
      rowCount = 4;
      colInRow = index - 19;
    }

    // Vertical placement: distribute rows from top (apex) to bottom within usable area
    final double y = padding + usable * (row / 4);

    // Horizontal placement: triangle width increases by row
    // Compute the row's left/right bounds so rows are centered forming a triangle
    final double rowMinX;
    final double rowMaxX;
    switch (row) {
      case 0:
        rowMinX = 0.5;
        rowMaxX = 0.5;
        break;
      case 1:
        rowMinX = 0.20;
        rowMaxX = 0.80;
        break;
      case 2:
        rowMinX = 0.16;
        rowMaxX = 0.84;
        break;
      case 3:
        rowMinX = 0.12;
        rowMaxX = 0.88;
        break;
      default: // row 4
        rowMinX = 0.28;
        rowMaxX = 0.72;
        break;
    }

    // Convert normalized row bounds into padded coordinates
    final double minX = padding + usable * rowMinX;
    final double maxX = padding + usable * rowMaxX;

    // Evenly distribute columns across [minX, maxX]
    final double x = rowCount == 1
        ? minX
        : minX + (maxX - minX) * (colInRow / (rowCount - 1));

    // Clamp to 0..1 bounds in case of rounding
    return Offset(
      x.clamp(0.0, 1.0),
      y.clamp(0.0, 1.0),
    );
  }
}

