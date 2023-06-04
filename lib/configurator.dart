import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:mesh_gradient/dot.dart';
import 'package:mesh_gradient/extensions.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:mesh_gradient/picker.dart';

class MeshGradientConfiguration extends StatefulWidget {
  const MeshGradientConfiguration({
    super.key,
    this.rows = 3,
    this.columns = 3,
    this.previewResolution = 0.05,
    this.debugGrid = false,
  });

  final int rows;
  final int columns;
  final double previewResolution;
  final bool debugGrid;

  @override
  State<MeshGradientConfiguration> createState() =>
      _MeshGradientConfigurationState();
}

class _MeshGradientConfigurationState extends State<MeshGradientConfiguration> {
  final overlayController = OverlayPortalController();
  final link = LayerLink();

  @override
  void initState() {
    super.initState();
    fillLists();
    overlayController.show();
  }

  @override
  void dispose() {
    overlayController.hide();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MeshGradientConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows || oldWidget.columns != widget.columns) {
      fillLists();
    }
  }

  void fillLists() {
    positions.clear();
    colors.clear();
    for (int i = 0; i < widget.rows; i++) {
      final row = <Alignment>[];
      final colorRow = <OklabColor>[];
      for (int j = 0; j < widget.columns; j++) {
        row.add(Alignment(
          (j / (widget.columns - 1)) * 2 - 1,
          (i / (widget.rows - 1)) * 2 - 1,
        ));
        colorRow.add(HslColor.random(
          seed: i * widget.rows + j,
          minLightness: 5,
          minSaturation: 50,
        ).toOklabColor());
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

  Offset? _mousePosition;
  (int, int)? _selectedDot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MouseRegion(
        onHover: (event) {
          if (event.kind == PointerDeviceKind.mouse ||
              event.kind == PointerDeviceKind.trackpad) {
            setState(() => _mousePosition = event.localPosition);
          }
        },
        onExit: (event) {
          if (event.localPosition.dx <= 0 ||
              event.localPosition.dx >= constraints.biggest.width ||
              event.localPosition.dy <= 0 ||
              event.localPosition.dy >= constraints.biggest.height) {
            setState(() {
              _mousePosition = null;
            });
          }
        },
        child: OverlayPortal(
          controller: overlayController,
          overlayChildBuilder: (context) {
            return LayoutBuilder(builder: (context, _) {
              return CompositedTransformFollower(
                link: link,
                offset: centerDotOffset,
                child: Stack(
                  children: [
                    for (int i = 0; i < positions.length; i++)
                      for (int j = 0; j < positions[i].length; j++)
                        Positioned(
                          left: (positions[i][j].x / 2 + 0.5) *
                              constraints.biggest.width,
                          top: (positions[i][j].y / 2 + 0.5) *
                              constraints.biggest.height,
                          child: Listener(
                            onPointerMove: (details) {
                              final newPosition = (positions[i][j]
                                          .alongSize(constraints.biggest) +
                                      details.delta)
                                  .clamp(constraints);
                              var newMousePosition = _mousePosition;
                              // also update the _mousePosition for the hover effect
                              if (_mousePosition != null) {
                                newMousePosition =
                                    _mousePosition! + details.delta;
                              }
                              if (details.kind == PointerDeviceKind.touch ||
                                  details.kind == PointerDeviceKind.stylus) {
                                newMousePosition = null;
                              }
                              setState(
                                () {
                                  positions[i][j] = newPosition
                                      .alignmentIn(constraints.biggest);
                                  _mousePosition = newMousePosition;
                                },
                              );
                            },
                            child: AnimatedScale(
                              filterQuality: FilterQuality.low,
                              duration: const Duration(milliseconds: 100),
                              scale: switch ((_mousePosition, _selectedDot)) {
                                (null, null) => 1,
                                (_, (int ii, int jj)) =>
                                  (ii == i && jj == j) ? 1 : 0.2,
                                (Offset mousePosition, _) => () {
                                    final distanceX = (mousePosition.dx -
                                            (positions[i][j].x / 2 + 0.5) *
                                                constraints.biggest.width)
                                        .abs();
                                    final distanceY = (mousePosition.dy -
                                            (positions[i][j].y / 2 + 0.5) *
                                                constraints.biggest.height)
                                        .abs();
                                    final distance =
                                        Offset(distanceX, distanceY)
                                            .distanceSquared;
                                    final distanceNormalized = distance /
                                        constraints.biggest
                                            .bottomRight(Offset.zero)
                                            .distanceSquared;
                                    return max(
                                        0.2, 1 - distanceNormalized * 10);
                                  }()
                              },
                              child: PickerDot(
                                color: colors[i][j],
                                dotStyle: const DotThemeData().copyWith(
                                  border: colors[i][j],
                                  cursor: SystemMouseCursors.move,
                                ),
                                origin: link.leader == null
                                    ? Offset.zero
                                    : link.leader!.offset + centerDotOffset,
                                onSelectionStateChanged: (isSelecting) =>
                                    setState(
                                  () {
                                    if (isSelecting) {
                                      _selectedDot = (i, j);
                                    } else {
                                      _selectedDot = null;
                                    }
                                  },
                                ),
                                onColorChanged: (cl) =>
                                    setState(() => colors[i][j] = cl),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              );
            });
          },
          child: CompositedTransformTarget(
            link: link,
            child: CustomPaint(
              isComplex: true,
              painter: MeshGradientPainter(
                positions,
                colors,
                resolution: widget.previewResolution,
                debugGrid: widget.debugGrid,
              ),
              foregroundPainter:
                  (_mousePosition == null || _selectedDot != null)
                      ? null
                      : IsoLinePainter(
                          positions,
                          _mousePosition!.alignmentIn(constraints.biggest),
                        ),
            ),
          ),
        ),
      );
    });
  }
}

class IsoLinePainter extends CustomPainter {
  final List<List<Alignment>> controlPoints;
  final Alignment centerPoint;
  final int segments;

  const IsoLinePainter(this.controlPoints, this.centerPoint,
      {this.segments = 36});

  @override
  void paint(Canvas canvas, Size size) {
    final surface = BezierPatchSurface(controlPoints);

    for (final (radius: radius, strokeWidth: strokeWidth, alpha: alpha)
        in <({double radius, double strokeWidth, int alpha})>[
      (radius: 0.18, strokeWidth: 1, alpha: 32),
      (radius: 0.29, strokeWidth: 1, alpha: 16),
      (radius: 0.40, strokeWidth: 1, alpha: 8),
      (radius: 0.51, strokeWidth: 1, alpha: 4),
      (radius: 0.61, strokeWidth: 1, alpha: 2),
    ]) {
      final path = Path();

      var moved = false;
      for (int i = 0; i <= segments; i++) {
        final angle = i / segments * 2 * pi;
        final evaluationOffset =
            Alignment(cos(angle), sin(angle)) * radius + centerPoint;
        final evaluatedPoint = surface
            .evaluate(
                evaluationOffset.y / 2 + 0.5, evaluationOffset.x / 2 + 0.5)
            .alongSize(size);
        if (moved) {
          path.lineTo(evaluatedPoint.dx, evaluatedPoint.dy);
        } else {
          path.moveTo(evaluatedPoint.dx, evaluatedPoint.dy);
          moved = true;
        }
      }

      canvas.drawPath(
          path,
          Paint()
            ..color = Color.fromARGB(alpha, 0, 0, 0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth);
    }
  }

  @override
  bool shouldRepaint(IsoLinePainter oldDelegate) =>
      segments != oldDelegate.segments ||
      centerPoint != oldDelegate.centerPoint ||
      !controlPoints.equals(oldDelegate.controlPoints);
}
