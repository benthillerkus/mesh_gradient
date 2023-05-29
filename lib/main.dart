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

List<List<Quad>> quadsFromControlPoints(int rows, int columns) {
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

late Canvas globalCanvas;
late Paint dbgPaint;

void dbgPoint(Offset p) {
  globalCanvas.drawCircle(p, 5.0, dbgPaint);
}

class BezierPatchSurface {
  final List<List<Offset>> _controlPoints;

  BezierPatchSurface(this._controlPoints);

  Offset evaluate(double u, double v) {
    int n = _controlPoints.length - 1;

    final uPoints = [
      for (int i = 0; i <= n; i++) _deCasteljau(_controlPoints[i], v)
    ];

    return _deCasteljau(uPoints, u);
  }

  Offset _deCasteljau(List<Offset> points, double t) {
    if (t == 0) return points[0];
    if (t == 1) return points[points.length - 1];
    if (points.length == 1) return points[0];

    int n = points.length - 1;
    List<Offset> tempPoints = points.toList(growable: false);

    for (int r = 1; r <= n; r++) {
      for (int i = 0; i <= n - r; i++) {
        tempPoints[i] = (tempPoints[i] * (1 - t)) + (tempPoints[i + 1] * t);
      }
    }

    // dbgPoint(tempPoints[0]);

    return tempPoints[0];
  }
}

extension on Offset {
  Alignment alignmentIn(Size size) =>
      Alignment(dx / size.width * 2 - 1, dy / size.height * 2 - 1);
}

typedef Quad = ({int topLeft, int topRight, int bottomLeft, int bottomRight});

Iterable<List<int>> triangulateQuads(Iterable<Quad> quadFaces) sync* {
  for (final quadFace in quadFaces) {
    yield [quadFace.topLeft, quadFace.topRight, quadFace.bottomRight];
    yield [quadFace.topLeft, quadFace.bottomRight, quadFace.bottomLeft];
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
    globalCanvas = canvas;
    dbgPaint = Paint()..color = const Color.fromARGB(255, 0, 255, 0);

    final surface = BezierPatchSurface([
      [
        positions[0].alongSize(size),
        positions[1].alongSize(size),
        positions[2].alongSize(size)
      ],
      [
        positions[3].alongSize(size),
        positions[4].alongSize(size),
        positions[5].alongSize(size)
      ],
      [
        positions[6].alongSize(size),
        positions[7].alongSize(size),
        positions[8].alongSize(size)
      ],
    ]);

    final quads = quadsFromControlPoints(rows * 2 + 1, columns * 2 + 1);
    final ppositions = <Offset>[];
    for (int i = 0; i <= rows * 2; i++) {
      for (int j = 0; j <= columns * 2; j++) {
        ppositions.add(surface.evaluate(i / (rows * 2), j / (columns * 2)));
      }
    }

    // print(ppositions.length);
    // for (final p in ppositions) {
    //   print(p);
    // }

    // print(quads.length);
    // for (final rq in quads) {
    //   for (final cq in rq) {
    //     print(cq);
    //   }
    // }

    final triangles = triangulateQuads(quads.flattened);
    final mypositions = <Offset>[];
    // final mycolors = <Color>[];
    for (final triangle in triangles) {
      for (final index in triangle) {
        mypositions.add(ppositions[index]);
        // mycolors.add(this.colors[index].toColor());
      }
    }

    for (final p in ppositions) {
      canvas.drawCircle(p, 2, dbgPaint);
    }

    final vertices = Vertices(VertexMode.triangles, mypositions);
    canvas.drawVertices(
      vertices,
      // BlendMode.dstOver,
      BlendMode.srcOver,
      Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 1
        ..color = const Color.fromARGB(20, 255, 255, 255),
    );
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
