import 'package:flutter/widgets.dart';

class PseudoElements extends StatelessWidget {
  const PseudoElements({
    super.key,
    required this.child,
    this.before,
    this.after,
    this.gap = 0,
  });

  final Widget child;
  final Widget? before;
  final Widget? after;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
        delegate: _PseudoElementsDelegate(gap: gap),
        children: [
          if (before != null) LayoutId(id: 1, child: before!),
          if (after != null) LayoutId(id: 2, child: after!),
          LayoutId(id: 0, child: child),
        ]);
  }
}

class _PseudoElementsDelegate extends MultiChildLayoutDelegate {
  _PseudoElementsDelegate({this.gap = 0});

  final double gap;

  @override
  void performLayout(Size size) {
    final mainSize = layoutChild(0, BoxConstraints.loose(size));
    final sideConstraints = BoxConstraints(
      maxWidth: (size.width - mainSize.width - gap) / 2,
      minHeight: mainSize.height,
      maxHeight: mainSize.height,
    );
    layoutChild(1, sideConstraints);
    layoutChild(2, sideConstraints);
    positionChild(0, Offset((size.width - mainSize.width) / 2, 0));
    positionChild(1, Offset.zero);
    positionChild(2, Offset(size.width - sideConstraints.maxWidth, 0));
  }

  @override
  bool shouldRelayout(_PseudoElementsDelegate oldDelegate) {
    return gap != oldDelegate.gap;
  }
}