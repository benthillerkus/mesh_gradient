import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mess_gradients/conversions.dart';
import 'package:mess_gradients/picker.dart';
import 'package:flutter_color_models/flutter_color_models.dart';

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

    final pickerPosition = useState<Offset?>(null);
    final picker2Position = useState<Offset?>(null);

    return Center(
      child: SizedBox.square(
          dimension: 400,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _Painter(
                    color.value.lch,
                    color2.value.lch,
                  ),
                ),
              ),
              Positioned(
                left: pickerPosition.value?.dx,
                top: pickerPosition.value?.dy,
                child: Listener(
                  onPointerMove: (details) {
                    pickerPosition.value = (pickerPosition.value ?? Offset.zero) + details.delta;
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
                    picker2Position.value = (picker2Position.value ?? Offset.zero) + details.delta;
                  },
                  child: PickerDot(
                      color: color2.value,
                      onColorChanged: (cl) => color2.value = cl),
                ),
              )
            ],
          )),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter(this.color, this.color2);
  final LCH color;
  final LCH color2;

  @override
  void paint(Canvas canvas, Size size) {
    fragmentShader.setFloat(0, size.width);
    fragmentShader.setFloat(1, size.height);
    fragmentShader.setFloat(2, color.lightness);
    fragmentShader.setFloat(3, color.chroma);
    fragmentShader.setFloat(4, color.hue);
    fragmentShader.setFloat(5, color2.lightness);
    fragmentShader.setFloat(6, color2.chroma);
    fragmentShader.setFloat(7, color2.hue);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = fragmentShader);
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      color != oldDelegate.color || color2 != oldDelegate.color2;
}
