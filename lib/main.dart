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
  final colors = <OklabColor>[
    OklabColor.fromColor(const Color.fromARGB(255, 123, 02, 189)),
    OklabColor.fromColor(const Color.fromARGB(255, 62, 206, 5)),
    OklabColor.fromColor(const Color.fromARGB(255, 221, 224, 22)),
  ];

  final positions = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomCenter
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

extension on Offset {
  Alignment alignmentIn(Size size) =>
      Alignment(dx / size.width * 2 - 1, dy / size.height * 2 - 1);
}

class _Painter extends CustomPainter {
  const _Painter(this.positions, this.colors);
  final List<OklabColor> colors;
  final List<Alignment> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final vertices = Vertices(
      VertexMode.triangles,
      positions.map((e) => e.alongSize(size)).toList(),
      colors: colors.map((e) => e.toColor()).toList(),
    );
    canvas.drawVertices(vertices, BlendMode.dstOver, Paint());
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      !colors.equals(oldDelegate.colors) ||
      !positions.equals(oldDelegate.positions);
}
