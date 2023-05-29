import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mess_gradients/conversions.dart';
import 'package:mess_gradients/dot.dart';
import 'package:mess_gradients/main.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

class PickerDot extends HookWidget {
  const PickerDot(
      {super.key,
      required this.color,
      required this.onColorChanged,
      this.dotStyle = const DotThemeData(),
      this.pickerRadius = 100});

  final DotThemeData dotStyle;
  final OklabColor color;
  final void Function(OklabColor) onColorChanged;
  final double pickerRadius;

  void handleWheelInteraction(Offset position) {
    final angle = atan2(position.dy - pickerRadius, position.dx - pickerRadius);
    final c = sqrt(color.a * color.a + color.b * color.b);
    onColorChanged(OklabColor(color.lightness, cos(angle) * c, sin(angle) * c));
  }

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(OverlayPortalController.new);
    final link = useMemoized(LayerLink.new);

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
                  onTap: controller.toggle,
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
                child: Listener(
                  onPointerDown: (details) {
                    if (Offset(
                          details.localPosition.dy - pickerRadius,
                          details.localPosition.dx - pickerRadius,
                        ).distance >
                        (pickerRadius - dotStyle.radius * 2 - 8)) {
                      handleWheelInteraction(details.localPosition);
                    } else {
                      controller.toggle();
                    }
                  },
                  onPointerMove: (details) {
                    if (controller.isShowing) {
                      handleWheelInteraction(details.localPosition);
                    }
                  },
                  child: SizedBox.square(
                    dimension: pickerRadius * 2,
                    child: CustomPaint(
                      painter: PickerPainter(
                        color.lch,
                        stroke: dotStyle.radius * 2,
                      ),
                      child: Align(
                          alignment:
                              Alignment(cos(color.lch.hue), sin(color.lch.hue)),
                          child: Dot(
                            style: dotStyle,
                          )),
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
          onTap: controller.toggle,
        ),
      ),
    );
  }
}

class PickerPainter extends CustomPainter {
  const PickerPainter(this.color, {this.stroke = 20});
  final LCH color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final circleCenter = Offset(size.width / 2, size.height / 2);
    final fullRadius = (size.width - stroke) / 2;
    pickerFragmentShader.setFloat(0, size.width);
    pickerFragmentShader.setFloat(1, size.height);
    pickerFragmentShader.setFloat(2, color.lightness);
    pickerFragmentShader.setFloat(3, color.chroma);
    pickerFragmentShader.setFloat(4, color.hue);
    canvas.drawArc(
        Rect.fromCircle(center: circleCenter, radius: fullRadius),
        0,
        pi * 2,
        false,
        Paint()
          ..shader = pickerFragmentShader
          ..strokeWidth = stroke
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(PickerPainter oldDelegate) => color != oldDelegate.color;
}
