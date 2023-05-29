import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mess_gradients/conversions.dart';
import 'package:mess_gradients/dot.dart';
import 'package:mess_gradients/picker.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:collection/collection.dart';

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

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final color =
        useState(OklabColor.fromColor(const Color.fromARGB(255, 56, 192, 108)));
    final color2 =
        useState(OklabColor.fromColor(const Color.fromARGB(255, 123, 02, 189)));
    final color3 =
        useState(OklabColor.fromColor(const Color.fromARGB(255, 216, 185, 47)));

    final pickerPosition = useState<Offset?>(null);
    final picker2Position = useState<Offset?>(null);
    final picker3Position = useState<Offset?>(null);

    return Center(
      child: SizedBox.square(
          dimension: 400,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _Painter(
                    offset: Offset(
                      const DotThemeData().radius,
                      const DotThemeData().radius,
                    ),
                    [
                      pickerPosition.value ?? Offset.zero,
                      picker2Position.value ?? Offset.zero,
                      picker3Position.value ?? Offset.zero,
                    ],
                    [
                      color.value,
                      color2.value,
                      color3.value,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: pickerPosition.value?.dx,
                top: pickerPosition.value?.dy,
                child: Listener(
                  onPointerMove: (details) {
                    pickerPosition.value =
                        (pickerPosition.value ?? Offset.zero) + details.delta;
                  },
                  child: PickerDot(
                      color: color.value,
                      onColorChanged: (cl) => color.value = cl),
                ),
              ),
              Positioned(
                left: picker2Position.value?.dx,
                top: picker2Position.value?.dy,
                child: Listener(
                  onPointerMove: (details) {
                    picker2Position.value =
                        (picker2Position.value ?? Offset.zero) + details.delta;
                  },
                  child: PickerDot(
                      color: color2.value,
                      onColorChanged: (cl) => color2.value = cl),
                ),
              ),
              Positioned(
                left: picker3Position.value?.dx,
                top: picker3Position.value?.dy,
                child: Listener(
                  onPointerMove: (details) {
                    picker3Position.value =
                        (picker3Position.value ?? Offset.zero) + details.delta;
                  },
                  child: PickerDot(
                      color: color3.value,
                      onColorChanged: (cl) => color3.value = cl),
                ),
              )
            ],
          )),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter(this.positions, this.colors, {this.offset = Offset.zero});
  final List<OklabColor> colors;
  final List<Offset> positions;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final vertices = Vertices(
      VertexMode.triangles,
      positions.map((e) => e + offset).toList(),
      colors: colors.map((e) => e.toColor()).toList(),
    );
    canvas.drawVertices(vertices, BlendMode.dstOver, Paint());
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      offset != oldDelegate.offset ||
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
