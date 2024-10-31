// ignore_for_file: type_literal_in_constant_pattern

import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

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
      OklabColor => ((OklabColor? a, OklabColor? b, double t) =>
          a!.interpolate(b!, t)) as T? Function(T? a, T? b, double t),
      Color => Color.lerp as T? Function(T? a, T? b, double t),
      Alignment => Alignment.lerp as T? Function(T? a, T? b, double t),
      Size => Size.lerp as T? Function(T? a, T? b, double t),
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

typedef Quad = ({int topLeft, int topRight, int bottomLeft, int bottomRight});

Iterable<List<int>> triangulateQuads(Iterable<Quad> quadFaces) sync* {
  for (final quadFace in quadFaces) {
    yield [quadFace.topLeft, quadFace.topRight, quadFace.bottomRight];
    yield [quadFace.topLeft, quadFace.bottomRight, quadFace.bottomLeft];
  }
}

class MeshGradientPainter extends CustomPainter {
  const MeshGradientPainter(
    this.positions,
    this.colors, {
    this.key,
    this.resolution = 0.05,
    this.debugGrid = false,
  });

  /// The key is used to distinguish the use of this painter in one place
  /// from another.
  ///
  /// This allows the painter to reuse some buffers and avoid unnecessary
  /// allocations.
  final Key? key;
  final List<List<OklabColor>> colors;
  final List<List<Alignment>> positions;
  final double resolution;
  final bool debugGrid;

  static final Map<(int, int), Uint16List> _indicesCache = {};

  static final Map<Key, Float32List> _positionsCache = {};
  static final Map<Key, Int32List> _colorsCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final xRes = (size.width * resolution).toInt();
    final yRes = (size.height * resolution).toInt();

    final surface = BezierPatchSurface(positions);
    final colorSurface = BezierPatchSurface(colors);

    final Float32List evaluatedPositions;
    final Int32List evaluatedColors;
    final evaluatedPositionsLength = yRes * xRes * 2;
    final evaluatedColorsLength = yRes * xRes;
    if (key == null) {
      evaluatedPositions = Float32List(evaluatedPositionsLength);
      evaluatedColors = Int32List(evaluatedColorsLength);
    } else {
      if (!_positionsCache.containsKey(key) ||
          _positionsCache[key]!.length < evaluatedPositionsLength) {
        _positionsCache[key!] = Float32List(evaluatedPositionsLength);
        _colorsCache[key!] = Int32List(evaluatedColorsLength);
      }
      evaluatedPositions = _positionsCache[key]!;
      evaluatedColors = _colorsCache[key]!;
    }

    {
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
    }

    final indices = _indicesCache.putIfAbsent((yRes, xRes), () {
      return Uint16List.fromList(
          triangulateQuads(quadsFromControlPoints(yRes, xRes).flattened)
              .flattened
              .toList());
    });

    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(evaluatedPositions, 0, evaluatedPositionsLength),
      colors: Int32List.sublistView(evaluatedColors, 0, evaluatedColorsLength),
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
  bool shouldRepaint(MeshGradientPainter oldDelegate) =>
      debugGrid != oldDelegate.debugGrid ||
      resolution != oldDelegate.resolution ||
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
