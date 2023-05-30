import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DotThemeData {
  const DotThemeData({
    this.fill = const Color.fromARGB(120, 255, 255, 255),
    this.border = const Color.fromARGB(180, 255, 255, 255),
    this.radius = 20,
    this.thickness = 2,
    this.cursor = SystemMouseCursors.click,
  });

  final Color fill;
  final Color border;
  final double radius;
  final double thickness;
  final MouseCursor cursor;

  DotThemeData copyWith({
    Color? fill,
    Color? border,
    double? radius,
    double? thickness,
    MouseCursor? cursor,
  }) =>
      DotThemeData(
        fill: fill ?? this.fill,
        border: border ?? this.border,
        radius: radius ?? this.radius,
        thickness: thickness ?? this.thickness,
        cursor: cursor ?? this.cursor,
      );
}

class Dot extends HookWidget {
  const Dot({super.key, this.style = const DotThemeData(), this.onTap});

  final DotThemeData style;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final fillColor = useState(style.fill);

    return GestureDetector(
      onTap: onTap,
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) =>
            fillColor.value = value ? style.fill.withAlpha(170) : style.fill,
        mouseCursor: style.cursor,
        child: TweenAnimationBuilder(
          tween: ColorTween(
              begin: usePrevious(fillColor.value), end: fillColor.value),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) => DecoratedBox(
            decoration: BoxDecoration(
                color: value,
                border: Border.all(
                    color: style.border,
                    width: style.thickness,
                    style: style.thickness == 0
                        ? BorderStyle.none
                        : BorderStyle.solid),
                shape: BoxShape.circle),
            child: SizedBox.square(dimension: style.radius * 2),
          ),
        ),
      ),
    );
  }
}
