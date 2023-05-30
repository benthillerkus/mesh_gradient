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
    final hover = useState(false);
    final hasFocus = useState(false);

    return GestureDetector(
      onTap: onTap,
      child: FocusableActionDetector(
        autofocus: true,
        onShowHoverHighlight: (value) => hover.value = value,
        onShowFocusHighlight: (value) => hasFocus.value = value,
        mouseCursor: style.cursor,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: switch ((hover.value, hasFocus.value)) {
                (true, false) => style.fill.withAlpha(170),
                (_, true) => style.fill.withAlpha(200),
                (false, false) => style.fill.withAlpha(120),
              },
              border: Border.all(color: style.border, width: style.thickness),
              shape: BoxShape.circle),
          child: SizedBox.square(dimension: style.radius * 2),
        ),
      ),
    );
  }
}
