import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mesh_gradient/dot.dart';
import 'package:mesh_gradient/extensions.dart';
import 'package:mesh_gradient/main.dart';

class PickerDot extends HookWidget {
  const PickerDot({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.dotStyle = const DotThemeData(),
    this.onSelectionStateChanged,
    this.pickerRadius = 100,
    this.smallerBarRadius = 12,
  });

  final DotThemeData dotStyle;
  final OklabColor color;
  final void Function(OklabColor) onColorChanged;
  final void Function(bool isSelecting)? onSelectionStateChanged;
  final double pickerRadius;
  final double smallerBarRadius;
  double get adjustedPickerRadius =>
      pickerRadius + Offset(color.a, color.b).distance * 180;

  void handleChromaInteraction(Offset position, {Offset? delta}) {
    final angle = position.direction;

    var c = Offset(color.a, color.b).distance;
    if (delta != null) {
      if (position.distance > adjustedPickerRadius) {
        c += delta.distance * 2 / 180;
      } else if (position.distance <
          adjustedPickerRadius - dotStyle.radius * 2) {
        c -= delta.distance * 2 / 180;
      }
    }
    c = c.clamp(0, 1);
    onColorChanged(OklabColor(color.lightness, cos(angle) * c, sin(angle) * c));
  }

  void handleLuminanceInteraction(Offset position) {
    final angle = position.direction % (2 * pi);
    onColorChanged(OklabColor(
        pow(angle / (pi * 2), 1 / 2.2).toDouble(), color.a, color.b));
  }

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(OverlayPortalController.new);
    final link = useMemoized(LayerLink.new);
    final editInnerWheel = useState(true);
    final previousEditInnerWheel = usePrevious(editInnerWheel.value);

    void toggle() {
      controller.toggle();
      onSelectionStateChanged?.call(controller.isShowing);
    }

    return OverlayPortal(
      controller: controller,
      // The LayoutBuilder is just there to ensure that resizing the window will recalculate the keepOnScreen offset
      overlayChildBuilder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final leaderScreenPosition = link.leader?.offset;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: toggle,
                  // For some reason the DecoratedBox is needed, otherwise the Size of the Layout will be 0
                  child: const DecoratedBox(
                    decoration: BoxDecoration(),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              CompositedTransformFollower(
                targetAnchor: Alignment.center,
                followerAnchor: Alignment.center,
                link: link,
                // offset: keepOnScreen,
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (details) {
                      final distance = (details.localPosition -
                              Offset(adjustedPickerRadius + smallerBarRadius,
                                  adjustedPickerRadius + smallerBarRadius))
                          .distance;
                      if (distance > adjustedPickerRadius &&
                          editInnerWheel.value) {
                        editInnerWheel.value = false;
                      } else if (distance <
                              (adjustedPickerRadius - dotStyle.radius * 2) &&
                          !editInnerWheel.value) {
                        editInnerWheel.value = true;
                      } else if (distance >
                          (adjustedPickerRadius -
                              dotStyle.radius * 2 -
                              smallerBarRadius)) {
                        final normalizedPosition = details.localPosition -
                            Offset(adjustedPickerRadius, adjustedPickerRadius) -
                            Offset(smallerBarRadius, smallerBarRadius);
                        if (editInnerWheel.value) {
                          handleChromaInteraction(normalizedPosition);
                        } else {
                          handleLuminanceInteraction(normalizedPosition);
                        }
                      } else {
                        toggle();
                      }
                    },
                    onPointerMove: (details) {
                      if (controller.isShowing) {
                        final normalizedPosition = details.localPosition -
                            Offset(adjustedPickerRadius, adjustedPickerRadius) -
                            Offset(smallerBarRadius, smallerBarRadius);
                        if (editInnerWheel.value) {
                          handleChromaInteraction(normalizedPosition,
                              delta: details.localDelta);
                        } else {
                          handleLuminanceInteraction(normalizedPosition);
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(smallerBarRadius),
                      child: SizedBox.square(
                        dimension: adjustedPickerRadius * 2,
                        child: TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween<double>(
                              begin: previousEditInnerWheel ?? true ? 0 : 1,
                              end: editInnerWheel.value ? 0 : 1),
                          curve: Curves.ease,
                          builder: (context, value, child) => CustomPaint(
                            painter: PickerPainter(
                              color.lch,
                              stroke: dotStyle.radius * 2,
                              minStroke: smallerBarRadius,
                              selectorBalance: value,
                            ),
                            child: child,
                          ),
                          child: Align(
                            alignment: editInnerWheel.value
                                ? Alignment(
                                    cos(color.lch.hue), sin(color.lch.hue))
                                : () {
                                    final angle =
                                        pow(color.lightness, 2.2) * 2 * pi;
                                    return Alignment(
                                      cos(angle),
                                      sin(angle),
                                    );
                                  }(),
                            child: Dot(
                              style: dotStyle.copyWith(
                                fill: const Color.fromARGB(170, 255, 255, 255),
                                border:
                                    const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      child: CompositedTransformTarget(
        link: link,
        child: Dot(
          style: dotStyle,
          onTap: toggle,
        ),
      ),
    );
  }
}

class PickerPainter extends CustomPainter {
  const PickerPainter(this.color,
      {this.stroke = 20, this.minStroke = 8, this.selectorBalance = 1});
  final LCH color;
  final double stroke;
  final double minStroke;
  final double selectorBalance;

  @override
  void paint(Canvas canvas, Size size) {
    final circleCenter = Offset(size.width / 2, size.height / 2);
    pickerFragmentShader.setFloat(0, size.width);
    pickerFragmentShader.setFloat(1, size.height);
    pickerFragmentShader.setFloat(2, color.lightness);
    pickerFragmentShader.setFloat(3, color.chroma);
    pickerFragmentShader.setFloat(4, color.hue);
    final minWidth =
        size.width + ((size.width - stroke * 2) - size.width) * selectorBalance;
    final innerRadius =
        (minWidth - (stroke + (minStroke - stroke) * selectorBalance)) / 2;
    canvas.drawArc(
      Rect.fromCircle(center: circleCenter, radius: innerRadius),
      0,
      pi * 2,
      false,
      Paint()
        ..shader = pickerFragmentShader
        ..strokeWidth = stroke + (minStroke - stroke) * selectorBalance
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: circleCenter, radius: innerRadius + (stroke + minStroke) / 2),
      0,
      pi * 2 * pow(color.lightness, 2.2),
      false,
      Paint()
        ..color = const Color.fromARGB(170, 255, 255, 255)
        ..strokeWidth = stroke + (minStroke - stroke) * (1 - selectorBalance)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(PickerPainter oldDelegate) =>
      color != oldDelegate.color ||
      stroke != oldDelegate.stroke ||
      minStroke != oldDelegate.minStroke ||
      selectorBalance != oldDelegate.selectorBalance;
}
