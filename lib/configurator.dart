import 'dart:math';
import 'dart:ui';

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
  @override
  void initState() {
    super.initState();
    fillLists();
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                isComplex: true,
                painter: MeshGradientPainter(
                  positions,
                  colors,
                  resolution: widget.previewResolution,
                  debugGrid: widget.debugGrid,
                ),
              ),
            ),
            for (int i = 0; i < positions.length; i++)
              for (int j = 0; j < positions[i].length; j++)
                Positioned(
                  left:
                      (positions[i][j].x / 2 + 0.5) * constraints.biggest.width,
                  top: (positions[i][j].y / 2 + 0.5) *
                      constraints.biggest.height,
                  child: Transform.translate(
                    offset: centerDotOffset,
                    child: Listener(
                      onPointerMove: (details) {
                        setState(
                          () {
                            final newPosition = (positions[i][j]
                                        .alongSize(constraints.biggest) +
                                    details.delta)
                                .clamp(constraints);
                            positions[i][j] =
                                newPosition.alignmentIn(constraints.biggest);
                            // also update the _mousePosition for the hover effect
                            if (_mousePosition != null) {
                              _mousePosition = _mousePosition! + details.delta;
                            }
                            if (details.kind == PointerDeviceKind.touch ||
                                details.kind == PointerDeviceKind.stylus) {
                              _mousePosition = null;
                            }
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
                                  Offset(distanceX, distanceY).distanceSquared;
                              final distanceNormalized = distance /
                                  constraints.biggest
                                      .bottomRight(Offset.zero)
                                      .distanceSquared;
                              return max(0.2, 1 - distanceNormalized * 10);
                            }()
                        },
                        child: PickerDot(
                          color: colors[i][j],
                          dotStyle: const DotThemeData().copyWith(
                            border: colors[i][j],
                            cursor: SystemMouseCursors.move,
                          ),
                          onSelectionStateChanged: (isSelecting) => setState(
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
                ),
          ],
        ),
      );
    });
  }
}
