import 'dart:math';

import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter/widgets.dart';

extension ClampToConstraints on Offset {
  Offset clamp(BoxConstraints constraints) {
    return Offset(
      dx.clamp(0, constraints.maxWidth),
      dy.clamp(0, constraints.maxHeight),
    );
  }
}

extension AlignmentIn on Offset {
  Alignment alignmentIn(Size size) =>
      Alignment(dx / size.width * 2 - 1, dy / size.height * 2 - 1);
}

typedef LCH = ({double lightness, double chroma, double hue});
typedef LAB = ({double lightness, double a, double b});

extension LCHext on LCH {
  LAB get lab =>
      (lightness: lightness, a: cos(hue) * chroma, b: sin(hue) * chroma);
}

extension LABext on LAB {
  LCH get lch =>
      (lightness: lightness, chroma: sqrt(a * a + b * b), hue: atan2(b, a));
}

extension Records on OklabColor {
  LAB get lab => (lightness: lightness, a: a, b: b);
  LCH get lch => lab.lch;
}
