import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mess_gradients/dot.dart';
import 'package:mess_gradients/picker.dart';

late FragmentShader fragmentShader;
late FragmentShader pickerFragmentShader;

Future<void> main() async {
  final (fragmentProgram, pickerFragmentProgram) = await (
    FragmentProgram.fromAsset('assets/shader.glsl'),
    FragmentProgram.fromAsset('assets/picker.glsl')
  ).wait;
  fragmentShader = fragmentProgram.fragmentShader();
  pickerFragmentShader = pickerFragmentProgram.fragmentShader();
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: Overlay(
        initialEntries: [OverlayEntry(builder: (context) => const Home())]),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final positions = <Alignment>[
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  final colors = <OklabColor>[
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
    OklabColor.fromColor(const Color.fromARGB(255, 255, 122, 122)),
  ];

  final centerDotOffset = Offset(
    -const DotThemeData().radius,
    -const DotThemeData().radius,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
          dimension: 400,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Painter(
                      positions,
                      colors,
                      rows: 3,
                      columns: 3,
                    ),
                  ),
                ),
                for (int i = 0; i < colors.length; i++)
                  Positioned(
                    left:
                        (positions[i].x / 2 + 0.5) * constraints.biggest.width,
                    top:
                        (positions[i].y / 2 + 0.5) * constraints.biggest.height,
                    child: Transform.translate(
                      offset: centerDotOffset,
                      child: Listener(
                        onPointerMove: (details) {
                          setState(() {
                            final newPosition =
                                (positions[i].alongSize(constraints.biggest) +
                                    details.delta);
                            positions[i] =
                                newPosition.alignmentIn(constraints.biggest);
                          });
                        },
                        child: PickerDot(
                            color: colors[i],
                            onColorChanged: (cl) =>
                                setState(() => colors[i] = cl)),
                      ),
                    ),
                  ),
              ],
            );
          })),
    );
  }
}

extension on Offset {
  Alignment alignmentIn(Size size) =>
      Alignment(dx / size.width * 2 - 1, dy / size.height * 2 - 1);
}

typedef Quad = ({int topLeft, int topRight, int bottomLeft, int bottomRight});
typedef QuadGrid = List<List<Quad>>;
typedef Edge = ({int start, int end});

QuadGrid quadsFromControlPoints(int rows, int columns) {
  final grid = <List<Quad>>[];
  for (int i = 0; i < rows - 1; i++) {
    final row = <Quad>[];
    for (int j = 0; j < columns - 1; j++) {
      final topLeft = i * columns + j;
      final topRight = topLeft + 1;
      final bottomLeft = topLeft + columns;
      final bottomRight = bottomLeft + 1;
      row.add((
        topLeft: topLeft,
        topRight: topRight,
        bottomRight: bottomRight,
        bottomLeft: bottomLeft
      ));
    }
    grid.add(row);
  }
  return grid;
}

// List<Edge> edgesFromFaces(List<Face> faces) {
//   final Set<Edge> edges = {};
//   for (final face in faces) {
//     for (int i = 0; i < face.length; i++) {
//       edges.add((
//         start: face[i],
//         end: face[(i + 1) % face.length],
//       ));
//     }
//   }
//   return edges.toList();
// }

Iterable<List<int>> triangulateQuads(Iterable<Quad> quadFaces) sync* {
  for (final quadFace in quadFaces) {
    yield [quadFace.topLeft, quadFace.topRight, quadFace.bottomRight];
    yield [quadFace.topLeft, quadFace.bottomRight, quadFace.bottomLeft];
  }
}

(List<Offset>, List<ColorModel>, List<Quad>) subdivideCatmullClark(
    List<Offset> positions, List<ColorModel> colors, QuadGrid faces) {
  final facePoints = [
    for (final face in faces.flattened)
      (positions[face.topLeft] +
              positions[face.topRight] +
              positions[face.bottomLeft] +
              positions[face.bottomRight]) *
          0.25
  ];

  final edgePoints = <Offset>[];
  final positionEdgeMidpoints = List<Set<Offset>?>.filled(positions.length, null, growable: false);
  final rows = faces.length;
  final columns = faces[0].length;
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < columns; j++) {
      final face = faces[i][j];
      final facePoint = facePoints[i * columns + j];

      final topMidpoint = positions[face.topLeft] +
          (positions[face.topRight] - positions[face.topLeft]) * 0.5;
      final rightMidpoint = positions[face.topRight] +
          (positions[face.bottomRight] - positions[face.topRight]) * 0.5;
      final bottomMidpoint = positions[face.bottomLeft] +
          (positions[face.bottomRight] - positions[face.bottomLeft]) * 0.5;
      final leftMidpoint = positions[face.topLeft] +
          (positions[face.bottomLeft] - positions[face.topLeft]) * 0.5;

      face.topLeftMidPoint = topMidpoint;

      edgeMidPoints.add(topMidpoint);
      edgeMidPoints.add(rightMidpoint);
      edgeMidPoints.add(bottomMidpoint);
      edgeMidPoints.add(leftMidpoint);

      final top = facePoints.elementAtOrNull((i - 1) * columns + j);
      final right = facePoints.elementAtOrNull(i * columns + j + 1);
      final bottom = facePoints.elementAtOrNull((i + 1) * columns + j);
      final left = facePoints.elementAtOrNull(i * columns + j - 1);

      final topEdgePoint = top == null
          ? topMidpoint
          : (((top + facePoint) / 2) + topMidpoint) / 2;
      final rightEdgePoint = right == null
          ? rightMidpoint
          : (((right + facePoint) / 2) + rightMidpoint) / 2;
      final bottomEdgePoint = bottom == null
          ? bottomMidpoint
          : (((bottom + facePoint) / 2) + bottomMidpoint) / 2;
      final leftEdgePoint = left == null
          ? leftMidpoint
          : (((left + facePoint) / 2) + leftMidpoint) / 2;

      edgePoints.add(topEdgePoint);
      edgePoints.add(rightEdgePoint);
      edgePoints.add(bottomEdgePoint);
      edgePoints.add(leftEdgePoint);
    }
  }

  final newPositions = <Offset>[];
  final newColors = <ColorModel>[];

  for (int i = 0; i < positions.length; i++) {
    final position = positions[i];
    final color = colors[i];

    // 1. average of face points for faces touching this vertex
    final currentRow = i ~/ columns;
    final topLeftFacePoint =
        facePoints.elementAtOrNull(i - columns - currentRow - 1);
    final topRightFacePoint =
        facePoints.elementAtOrNull(i - columns - currentRow);
    final bottomLeftFacePoint = facePoints.elementAtOrNull(i - currentRow - 1);
    final bottomRightFacePoint = facePoints.elementAtOrNull(i - currentRow);
    final allFacePoints = [
      topLeftFacePoint,
      topRightFacePoint,
      bottomLeftFacePoint,
      bottomRightFacePoint
    ].whereType<Offset>().toList();
    final averageFacePoint =
        allFacePoints.reduce((a, b) => a + b) / facePoints.length.toDouble();

    // 2. average of edge midpoints for edges touching this vertex
    final rightEdgeMidPoint =
        edgeMidPoints.elementAtOrNull((i - currentRow) * 4) ??
            edgeMidPoints.elementAtOrNull((i - currentRow - 1) * 4 + 2);
    final bottomEdgeMidPoint =
        edgeMidPoints.elementAtOrNull((i - currentRow) * 4 + 3) ??
            edgeMidPoints.elementAtOrNull((i - currentRow - 1) * 4 + 1);
    final leftEdgeMidPoint =
        edgeMidPoints.elementAtOrNull((i - currentRow - 1) * 4);
    final topEdgeMidPoint =
        edgeMidPoints.elementAtOrNull((i - currentRow - 1) * 4 + 1);
  }
}

class _Painter extends CustomPainter {
  const _Painter(this.positions, this.colors,
      {required this.rows, required this.columns});
  final List<ColorModel> colors;
  final List<Alignment> positions;
  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final quads = quadsFromControlPoints(rows, columns);
    final triangles = triangulateQuads(quads.flattened);
    final positions = <Offset>[];
    final colors = <Color>[];
    for (final triangle in triangles) {
      for (final index in triangle) {
        positions.add(this.positions[index].alongSize(size));
        colors.add(this.colors[index].toColor());
      }
    }

    final vertices = Vertices(VertexMode.triangles, positions, colors: colors);
    canvas.drawVertices(vertices, BlendMode.dstOver, Paint());
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
