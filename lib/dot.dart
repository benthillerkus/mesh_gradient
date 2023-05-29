import 'package:flutter/widgets.dart';

class DotThemeData {
  const DotThemeData({
    this.fill = const Color.fromARGB(120, 255, 255, 255),
    this.border = const Color.fromARGB(180, 255, 255, 255),
    this.radius = 20,
    this.thickness = 2,
  });

  final Color fill;
  final Color border;
  final double radius;
  final double thickness;

  DotThemeData copyWith({
    Color? fill,
    Color? border,
    double? radius,
    double? thickness,
  }) =>
      DotThemeData(
        fill: fill ?? this.fill,
        border: border ?? this.border,
        radius: radius ?? this.radius,
        thickness: thickness ?? this.thickness,
      );
}

class Dot extends StatelessWidget {
  const Dot({super.key, this.style = const DotThemeData(), this.onTap});

  final DotThemeData style;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: style.fill,
            border: Border.all(color: style.border, width: style.thickness),
            shape: BoxShape.circle),
        child: SizedBox.square(dimension: style.radius * 2),
      ),
    );
  }
}
