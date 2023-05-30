import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:mesh_gradient/dot.dart';
import 'package:mesh_gradient/picker.dart';
import 'package:mesh_gradient/pathless.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';

late FragmentShader pickerFragmentShader;

Future<void> main() async {
  usePathUrlStrategy();

  final pickerFragmentProgram =
      await FragmentProgram.fromAsset('assets/picker.glsl');
  pickerFragmentShader = pickerFragmentProgram.fragmentShader();
  runApp(Directionality(
    textDirection: TextDirection.ltr,
    child: Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            return const Center(
              child: SizedBox.square(
                dimension: 600,
                child: MeshGradientConfiguration(
                  rows: 4,
                  columns: 4,
                  previewResolution: 0.05,
                ),
              ),
            );
          },
        )
      ],
    ),
  ));
}

class MeshGradientConfiguration extends StatefulWidget {
  const MeshGradientConfiguration(
      {super.key,
      this.rows = 3,
      this.columns = 3,
      this.previewResolution = 0.05});

  final int rows;
  final int columns;
  final double previewResolution;

  @override
  State<MeshGradientConfiguration> createState() =>
      _MeshGradientConfigurationState();
}

class _MeshGradientConfigurationState extends State<MeshGradientConfiguration> {
  @override
  void initState() {
    super.initState();
    fillLists();
  }

  @override
  void didUpdateWidget(covariant MeshGradientConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    fillLists();
  }

  void fillLists() {
    positions = [];
    colors = [];
    for (int i = 0; i < widget.rows; i++) {
      final row = <Alignment>[];
      final colorRow = <OklabColor>[];
      for (int j = 0; j < widget.columns; j++) {
        row.add(Alignment(
          (j / (widget.columns - 1)) * 2 - 1,
          (i / (widget.rows - 1)) * 2 - 1,
        ));
        colorRow.add(const OklabColor(1, 0.1, 0));
      }
      positions.add(row);
      colors.add(colorRow);
    }
  }

  List<List<Alignment>> positions = [];
  List<List<OklabColor>> colors = [];

  final centerDotOffset = Offset(
    -const DotThemeData().radius,
    -const DotThemeData().radius,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MeshGradientPainter(
                positions,
                colors,
                resolution: widget.previewResolution,
                debugGrid: false,
              ),
            ),
          ),
          for (int i = 0; i < positions.length; i++)
            for (int j = 0; j < positions[i].length; j++)
              Positioned(
                left: (positions[i][j].x / 2 + 0.5) * constraints.biggest.width,
                top: (positions[i][j].y / 2 + 0.5) * constraints.biggest.height,
                child: Transform.translate(
                  offset: centerDotOffset,
                  child: Listener(
                    onPointerMove: (details) {
                      setState(() {
                        final newPosition =
                            (positions[i][j].alongSize(constraints.biggest) +
                                    details.delta)
                                .clamp(constraints);
                        positions[i][j] =
                            newPosition.alignmentIn(constraints.biggest);
                      });
                    },
                    child: PickerDot(
                        color: colors[i][j],
                        dotStyle:
                            const DotThemeData().copyWith(border: colors[i][j]),
                        onColorChanged: (cl) =>
                            setState(() => colors[i][j] = cl)),
                  ),
                ),
              ),
        ],
      );
    });
  }
}

extension ClampToConstraints on Offset {
  Offset clamp(BoxConstraints constraints) {
    return Offset(
      dx.clamp(0, constraints.maxWidth),
      dy.clamp(0, constraints.maxHeight),
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

class BezierPatchSurface<T> {
  final List<List<T>> _controlPoints;

  BezierPatchSurface(this._controlPoints) {
    lerp = switch (T) {
      Offset => Offset.lerp as T? Function(T? a, T? b, double t),
      Color => Color.lerp as T? Function(T? a, T? b, double t),
      Alignment => Alignment.lerp as T? Function(T? a, T? b, double t),
      Size => Size.lerp as T? Function(T? a, T? b, double t),
      OklabColor => ((OklabColor? a, OklabColor? b, double t) =>
          a!.interpolate(b!, t)) as T? Function(T? a, T? b, double t),
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

class _MeshGradientPainter extends CustomPainter {
  const _MeshGradientPainter(this.positions, this.colors,
      {this.resolution = 0.05, this.debugGrid = false});
  final List<List<OklabColor>> colors;
  final List<List<Alignment>> positions;
  final double resolution;
  final bool debugGrid;

  static final Map<(int, int), Uint16List> _indicesCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final xRes = (size * resolution).width.toInt();
    final yRes = (size * resolution).height.toInt();

    final surface = BezierPatchSurface(positions);
    final colorSurface = BezierPatchSurface(colors);

    final indices = _indicesCache.putIfAbsent((yRes, xRes), () {
      return Uint16List.fromList(
          triangulateQuads(quadsFromControlPoints(yRes, xRes).flattened)
              .flattened
              .toList());
    });

    final evaluatedPositions = Float32List(yRes * xRes * 2);
    final evaluatedColors = Int32List(yRes * xRes);
    var epCounter = 0;
    var ecCounter = 0;
    for (int i = 0; i < yRes; i++) {
      for (int j = 0; j < xRes; j++) {
        final point =
            surface.evaluate(i / (yRes - 1), j / (xRes - 1)).alongSize(size);
        evaluatedPositions[epCounter++] = point.dx;
        evaluatedPositions[epCounter++] = point.dy;
        evaluatedColors[ecCounter++] =
            ((colorSurface.evaluate(i / (yRes - 1), j / (xRes - 1))).value);
      }
    }

    final vertices = Vertices.raw(
      VertexMode.triangles,
      evaluatedPositions,
      colors: evaluatedColors,
      indices: indices,
    );

    canvas.drawVertices(
      vertices,
      BlendMode.dstOver,
      Paint(),
    );

    if (debugGrid) {
      final dbgPaint = Paint()..color = const Color.fromARGB(255, 0, 255, 0);
      for (int i = 0; i < evaluatedPositions.length; i += 2) {
        canvas.drawCircle(
          Offset(evaluatedPositions[i], evaluatedPositions[i + 1]),
          2,
          dbgPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) =>
      resolution != oldDelegate.resolution ||
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
