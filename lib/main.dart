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

class BezierPatchSurface<T> {
  final List<List<T>> _controlPoints;

  BezierPatchSurface(this._controlPoints) {
    lerp = switch (T) {
      Offset => Offset.lerp as T? Function(T? a, T? b, double t),
      Color => Color.lerp as T? Function(T? a, T? b, double t),
      _ => throw UnsupportedError('Unsupported type $T'),
    };
  }

  final Map<double, List<T>> _cache = {};

  late final T? Function(T? a, T? b, double t) lerp;

  T evaluate(double u, double v) {
    int n = _controlPoints.length - 1;

    final hStrip = _cache.putIfAbsent(
        v,
        () =>
            [for (int i = 0; i <= n; i++) _deCasteljau(_controlPoints[i], v)]);

    return _deCasteljau(hStrip, u);
  }

  T _deCasteljau(List<T> points, double t) {
    if (t == 0) return points[0];
    if (t == 1) return points[points.length - 1];
    if (points.length == 1) return points[0];

    int n = points.length - 1;
    List<T> tempPoints = points.toList(growable: false);

    for (int r = 1; r <= n; r++) {
      for (int i = 0; i <= n - r; i++) {
        tempPoints[i] = lerp(tempPoints[i], tempPoints[i + 1], t) as T;
      }
    }

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
  final List<OklabColor> colors;
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
        positions[2].alongSize(size),
      ],
      [
        positions[3].alongSize(size),
        positions[4].alongSize(size),
        positions[5].alongSize(size),
      ],
      [
        positions[6].alongSize(size),
        positions[7].alongSize(size),
        positions[8].alongSize(size),
      ],
    ]);

    final colorSurface = BezierPatchSurface([
      [
        colors[0].toColor(),
        colors[1].toColor(),
        colors[2].toColor(),
      ],
      [
        colors[3].toColor(),
        colors[4].toColor(),
        colors[5].toColor(),
      ],
      [
        colors[6].toColor(),
        colors[7].toColor(),
        colors[8].toColor(),
      ],
    ]);

    final yRes = 7;
    final xRes = 7;

    final quads = quadsFromControlPoints(yRes, xRes);
    final evaluatedPositions = <Offset>[];
    final evaluatedColors = <Color>[];
    for (int i = 0; i < yRes; i++) {
      for (int j = 0; j < xRes; j++) {
        evaluatedPositions
            .add(surface.evaluate(i / (yRes - 1), j / (xRes - 1)));
        evaluatedColors
            .add(colorSurface.evaluate(i / (yRes - 1), j / (xRes - 1)));
      }
    }

    final triangles = triangulateQuads(quads.flattened);

    for (final p in evaluatedPositions) {
      canvas.drawCircle(p, 2, dbgPaint);
    }

    final vertices = Vertices(
      VertexMode.triangles,
      evaluatedPositions,
      colors: evaluatedColors,
      indices: triangles.flattened.toList(),
    );
    canvas.drawVertices(
      vertices,
      BlendMode.dstOver,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
