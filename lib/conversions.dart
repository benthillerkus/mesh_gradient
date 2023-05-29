import 'dart:math';

import 'package:flutter_color_models/flutter_color_models.dart';

typedef LCH = ({double lightness, double chroma, double hue});
typedef LAB = ({double lightness, double a, double b});

extension LCHext on LCH {
  LAB get lab =>
      (lightness: lightness, a: cos(hue) * chroma, b: sin(hue) * chroma);
}

extension LABext on LAB {
  LCH get lch =>
      (lightness: lightness, chroma: sqrt(a * a + b * b), hue: atan2(b, a));}

extension Records on OklabColor {
  LAB get lab => (lightness: lightness, a: a, b: b);
  LCH get lch => lab.lch;
}
