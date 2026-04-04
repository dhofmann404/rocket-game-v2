import 'dart:ui';

// 5 predefined rock fragment shapes (unit scale, centered at origin)
// Each is an irregular polygon resembling a broken rock piece
const List<List<Offset>> kStoneShapes = [
  // 0: Pentagon chunk (irregular)
  [
    Offset(0.1, -1.0),
    Offset(0.9, -0.4),
    Offset(0.75, 0.75),
    Offset(-0.55, 0.95),
    Offset(-0.95, -0.2),
  ],
  // 1: Flat slab
  [
    Offset(-1.2, -0.3),
    Offset(1.0, -0.5),
    Offset(1.25, 0.4),
    Offset(0.2, 0.6),
    Offset(-1.1, 0.5),
  ],
  // 2: Wedge / triangle chunk
  [
    Offset(0.1, -1.1),
    Offset(1.1, 0.55),
    Offset(0.3, 0.9),
    Offset(-1.0, 0.65),
  ],
  // 3: Rhombus shard
  [
    Offset(-0.3, -1.0),
    Offset(0.8, -0.2),
    Offset(0.45, 0.95),
    Offset(-0.7, 0.35),
    Offset(-0.9, -0.4),
  ],
  // 4: Hexagonal chunk
  [
    Offset(0.2, -1.0),
    Offset(0.9, -0.35),
    Offset(0.85, 0.55),
    Offset(0.1, 1.0),
    Offset(-0.8, 0.5),
    Offset(-0.9, -0.3),
  ],
];
