import 'package:flutter/material.dart';

import 'src.dart';

typedef ReorderableBuilder = Widget Function(BuildContext context, Animation<double> animation, bool inDrag);

/// The parent widget of every item in a [ImplicitlyAnimatedReorderableList].
class Reorderable extends StatefulWidget {
  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [ReorderableBuilder] `animation` parameter supplies you with an animation you can use to
  /// transition between the normal and the dragged state of the item. The `inDrag` parameter
  /// indicates whether this item is currently being dragged and you can use it to run implicit
  /// animations based on it.
  final ReorderableBuilder builder;
  const Reorderable({
    @required Key key,
    @required this.builder,
  })  : assert(key != null),
        assert(builder != null),
        super(key: key);

  @override
  ReorderableState createState() => ReorderableState();
}

class ReorderableState extends State<Reorderable> with SingleTickerProviderStateMixin {
  ValueKey key;

  AnimationController _dragController;
  CurvedAnimation _dragAnimation;

  ImplicitlyAnimatedReorderableListState _list;
  Animation<double> _translation;

  Duration duration;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(vsync: this, duration: Duration.zero);
    key = widget.key ?? ValueKey(DateTime.now().microsecondsSinceEpoch);

    didUpdateWidget(widget);
  }

  @override
  void didUpdateWidget(Reorderable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dragAnimation = CurvedAnimation(parent: _dragController, curve: Curves.linear);
  }

  bool _inDrag = false;
  bool get inDrag => _inDrag;
  set inDrag(bool value) {
    if (value != inDrag) {
      _inDrag = value;
      value ? _dragController.animateTo(1.0) : _dragController.animateBack(0.0);
    }
  }

  void setTranslation(Animation<double> animation) {
    if (mounted) {
      setState(() => _translation = animation);
    }
  }

  void _registerItem() {
    _list ??= ImplicitlyAnimatedReorderableListState.of(context);
    assert(_list != null, 'No ImplicitlyAnimatedListView was found in the hirachy!');

    _list?.registerItem(this);
    _dragController.duration = _list.widget.dragDuration;

    inDrag = _list.dragItem?.key == key && _list.inDrag;
  }

  @override
  Widget build(BuildContext context) {
    _registerItem();

    Widget buildChild([Animation animation]) {
      return widget.builder(
        context,
        animation ?? AlwaysStoppedAnimation(0.0),
        _inDrag,
      );
    }

    Widget child;
    if (_dragAnimation != null) {
      child = AnimatedBuilder(
        animation: _dragAnimation,
        builder: (context, _) => buildChild(_dragAnimation),
      );
    } else {
      child = buildChild();
    }

    if (_translation != null) {
      return AnimatedBuilder(
        animation: _translation,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translation.value),
            child: child,
          );
        },
      );
    }

    return child;
  }

  static ReorderableState of(BuildContext context) {
    return context.findAncestorStateOfType<ReorderableState>();
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }
}