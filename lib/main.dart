import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mesh_gradient/configurator.dart';
import 'package:mesh_gradient/pathless.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/link.dart';

late FragmentShader pickerFragmentShader;

Future<void> main() async {
  usePathUrlStrategy();

  final pickerFragmentProgram =
      await FragmentProgram.fromAsset('assets/picker.glsl');
  pickerFragmentShader = pickerFragmentProgram.fragmentShader();
  runApp(HookBuilder(builder: (context) {
    final brightness = usePlatformBrightness();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: GoogleFonts.vt323(
            fontSize: 20,
            color: brightness == Brightness.light
                ? const Color.fromARGB(255, 0, 0, 0)
                : const Color.fromARGB(255, 255, 255, 255)),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return const Home();
              },
            )
          ],
        ),
      ),
    );
  }));
}

class Home extends HookWidget {
  const Home({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showPointCloud = useState(false);
    final brightness = usePlatformBrightness();
    final rows = useState(3);
    final columns = useState(3);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: brightness == Brightness.light
              ? [
                  const Color.fromARGB(255, 216, 216, 216),
                  const Color.fromARGB(255, 255, 255, 255),
                ]
              : [
                  const Color.fromARGB(255, 63, 63, 63),
                  const Color.fromARGB(255, 0, 0, 0),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: Text(
                "Mesh Gradient Configurator",
                style: GoogleFonts.pirataOne(
                  fontSize: 36,
                  color: brightness == Brightness.light
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              children: [
                GestureDetector(
                  onTap: () => showPointCloud.value = !showPointCloud.value,
                  child: FocusableActionDetector(
                    mouseCursor: SystemMouseCursors.click,
                    child: Text(
                      "${showPointCloud.value ? "hide" : "show"} point cloud",
                    ),
                  ),
                ),
                GestureDetector(
                  onVerticalDragUpdate: (details) => rows.value =
                      (rows.value - details.delta.dy.toInt()).clamp(2, 12),
                  child: FocusableActionDetector(
                    mouseCursor: SystemMouseCursors.resizeRow,
                    child: Text(
                      "${rows.value.toString().padLeft(2)} rows",
                    ),
                  ),
                ),
                GestureDetector(
                  onHorizontalDragUpdate: (details) => columns.value =
                      (columns.value + details.delta.dx.toInt()).clamp(2, 12),
                  child: FocusableActionDetector(
                    mouseCursor: SystemMouseCursors.resizeColumn,
                    child: Text(
                      "${columns.value.toString().padLeft(2)} columns",
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: SizedBox.square(
                  dimension: 600,
                  child: MeshGradientConfiguration(
                    rows: rows.value,
                    columns: columns.value,
                    previewResolution: 0.05,
                    debugGrid: showPointCloud.value,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Link(
                  target: LinkTarget.blank,
                  uri: Uri.https("github.com", "benthillerkus/mesh_gradient"),
                  builder: (context, fn) => GestureDetector(
                    onTap: fn,
                    child: const FocusableActionDetector(
                        mouseCursor: SystemMouseCursors.click,
                        child: Text(
                          "benthillerkus/mesh_gradient",
                          style: TextStyle(
                            color: Color.fromARGB(255, 87, 126, 209),
                            decoration: TextDecoration.underline,
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
