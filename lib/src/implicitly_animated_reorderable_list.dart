import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'src.dart';

typedef ReorderStartedCallback<E> = void Function(E item, int index);

typedef ReorderFinishedCallback<E> = void Function(E item, int from, int to, List<E> items);

class ImplicitlyAnimatedReorderableList<E> extends ImplicitlyAnimatedListBase<Reorderable, E> {
  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// On iOS, this identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  final Duration dragDuration;

  /// Called in response to when the dragged item has been released
  /// and animated to its final destination. Here you should update
  /// the underlying data in your model/bloc/database etc.
  ///
  /// The `item` parameter of the callback is the item that has been reordered
  /// `from` index `to` index. The `data` parameter represents the new data with
  /// the item already being correctly reordered.
  final ReorderFinishedCallback<E> onReorderFinished;

  /// Called when an item changed from normal to dragged state and
  /// may be reordered.
  final ReorderStartedCallback<E> onReorderStarted;

  const ImplicitlyAnimatedReorderableList({
    Key key,
    @required List<E> items,
    @required AnimatedItemBuilder<Reorderable, E> itemBuilder,
    @required ItemDiffUtil<E> areItemsTheSame,
    RemovedItemBuilder<Reorderable, E> removeItemBuilder,
    UpdatedItemBuilder<Reorderable, E> updateItemBuilder,
    Duration insertDuration = const Duration(milliseconds: 500),
    Duration removeDuration = const Duration(milliseconds: 500),
    Duration updateDuration = const Duration(milliseconds: 500),
    this.dragDuration = const Duration(milliseconds: 300),
    @required this.onReorderFinished,
    this.onReorderStarted,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  })  : assert(itemBuilder != null),
        assert(areItemsTheSame != null),
        assert(onReorderFinished != null),
        assert(items != null),
        assert(
          dragDuration <= const Duration(milliseconds: 1500),
          'The drag duration is not allowed to take longer than 500 milliseconds.',
        ),
        super(
          key: key,
          items: items,
          itemBuilder: itemBuilder,
          areItemsTheSame: areItemsTheSame,
          removeItemBuilder: removeItemBuilder,
          updateItemBuilder: updateItemBuilder,
          insertDuration: insertDuration,
          removeDuration: removeDuration,
          updateDuration: updateDuration,
        );

  @override
  ImplicitlyAnimatedReorderableListState<E> createState() => ImplicitlyAnimatedReorderableListState<E>();
}

class ImplicitlyAnimatedReorderableListState<E>
    extends ImplicitlyAnimatedListBaseState<Reorderable, ImplicitlyAnimatedReorderableList<E>, E> {
  GlobalKey _dragKey;
  ScrollController controller;

  double _listHeight = 0;
  double get _offset => controller.offset;
  double get _maxOffset => controller.position.maxScrollExtent;
  double get _extent => _maxOffset + _listHeight;
  double get _scrollDelta => _offset - _dragStartScrollOffset;
  bool get _canScroll => _maxOffset > 0;
  Timer _scrollAdjuster;

  _Item dragItem;
  bool inDrag = false;
  double _dragStartDy;
  double _dragStartScrollOffset;
  Key get dragKey => dragItem?.key;
  int get dragIndex => dragItem?.index;
  double get dragTop => dragItem.top + _dragDelta;
  double get dragBottom => dragItem.bottom + _dragDelta;
  double get dragCenter => dragItem.center.dy + _dragDelta;
  double get draggedItemHeight => dragItem?.height;
  VoidCallback _onDragEnd;

  final ValueNotifier<double> _dragDeltaNotifier = ValueNotifier(0);
  double get _dragDelta => _dragDeltaNotifier.value;
  set _dragDelta(double value) => _dragDeltaNotifier.value = value;
  bool get up => _dragDelta.isNegative;
  bool motionUp = false;

  final ValueNotifier<double> _pointerDeltaNotifier = ValueNotifier(0);
  double get _pointerDelta => _pointerDeltaNotifier.value;
  set _pointerDelta(double value) => _pointerDeltaNotifier.value = value;

  Reorderable _dragWidget;
  final Map<Key, ReorderableState> _items = {};
  final Map<Key, AnimationController> _itemTranslations = {};
  final Map<Key, _Item> _itemBoxes = {};

  _Item get closest => closestList.firstOrNull;
  final List<_Item> closestList = [];

  @override
  void initState() {
    super.initState();
    _dragKey = GlobalKey();
    controller = widget.controller ?? ScrollController();
  }

  void onDragStarted(Key key) {
    _onDragEnd?.call();
    dragItem = _itemBoxes[key];

    if (dragIndex != null) {
      _dragStartDy = _itemOffset(key).dy;
      _dragStartScrollOffset = _offset;
      _findClosestItem();

      setState(() => inDrag = true);

      widget.onReorderStarted?.call(dataSet[dragIndex], dragIndex);

      _adjustScrollPositionWhenNecessary();
    }
  }

  void onDragUpdated(double delta, {bool isUpward}) {
    if (dragKey == null || dragItem == null) return;

    if (isUpward != null) {
      motionUp = isUpward;
    }

    // Allow the dragged item to be overscrolled to allow for
    // continous scrolling while in drag.
    final overscrollBound = _canScroll ? draggedItemHeight : 0;
    // Constrain the dragged item to the bounds of the list.
    final extent = (!up ? dragItem.bottom : dragItem.top) + delta;
    final minExtent = -(dragItem.top + overscrollBound);
    final maxExtent = _extent - overscrollBound;
    if (extent < minExtent || extent > maxExtent) {
      return;
    }

    _pointerDelta = delta.clamp(minExtent, maxExtent);
    _dragDelta = _pointerDelta + _scrollDelta;

    _findClosestItem();

    if (closest == null || closest.key == dragKey) return;

    _translateNextItem();
    _adjustPreviousItemTranslations();
  }

  void _findClosestItem() {
    closestList.clear();
    for (final item in _itemBoxes.values) {
      if (item == dragItem) {
        item.distance = _pointerDelta.abs();
        closestList.add(item);
      } else {
        final dy = item.center.dy;
        if ((motionUp && dragTop < dy) || (!motionUp && dragBottom > dy)) {
          item.distance = ((up ? dragTop : dragBottom) - dy).abs();
          closestList.add(item);
        }
      }
    }
    closestList.sort();
  }

  void _translateNextItem() {
    final tr = getTranslation(closest.key);
    final center = closest.center.dy;

    final key = closest.key;
    if (up) {
      if (dragTop < center && tr == 0.0) {
        _dispatchMove(key, draggedItemHeight);
      } else if (dragTop > center && tr != 0.0) {
        _dispatchMove(key, 0);
      }
    } else {
      if (dragBottom > center && tr == 0.0) {
        if (closest.distance > dragItem.height && !_canScroll) {
          return;
        }
        _dispatchMove(key, -draggedItemHeight);
      } else if (dragBottom < center && tr != 0.0) {
        _dispatchMove(key, 0);
      }
    }
  }

  void _adjustPreviousItemTranslations() {
    for (final item in _itemBoxes.values) {
      if (item == dragItem || item == closest) continue;

      final key = item.key;
      if (_itemTranslations[key]?.isAnimating == true) continue;

      final translation = getTranslation(key);

      final index = item.index;
      final closestIndex = closest.index;

      if (index > dragIndex) {
        if (translation == 0.0 && index < closestIndex) {
          _dispatchMove(key, -draggedItemHeight);
        } else if (translation != 0.0 && index > closestIndex) {
          _dispatchMove(key, 0);
        }
      } else if (index < dragIndex) {
        if (translation == 0.0 && index > closestIndex) {
          _dispatchMove(key, draggedItemHeight);
        } else if (translation != 0.0 && index < closestIndex) {
          _dispatchMove(key, 0);
        }
      }
    }
  }

  void _dispatchMove(Key key, double delta, {VoidCallback onEnd}) {
    double value = 0.0;
    final oldController = _itemTranslations[key];
    if (oldController != null) {
      value = oldController.value;

      oldController
        ..stop()
        ..dispose();
    }

    final start = min(value, delta);
    final end = max(value, delta);

    final controller = AnimationController(
      vsync: this,
      value: value,
      lowerBound: start,
      upperBound: end,
      duration: widget.dragDuration,
    );

    if (controller.upperBound == controller.lowerBound) {
      onEnd?.call();
      return;
    }

    _items[key]?.setTranslation(controller);

    // ignore: avoid_single_cascade_in_expression_statements
    controller.animateTo(
      delta,
      curve: Curves.easeInOut,
    )..whenCompleteOrCancel(
        () => onEnd?.call(),
      );

    _itemTranslations[key] = controller;
  }

  void _adjustScrollPositionWhenNecessary() {
    _scrollAdjuster?.cancel();
    _scrollAdjuster = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if ((up && _offset <= 0) || (!up && _offset >= _maxOffset)) return;

      final dragBox = _dragKey?.renderBox;
      if (dragBox == null) return;

      final dragItemTop = dragBox
          .localToGlobal(
            Offset.zero,
            ancestor: context.renderBox,
          )
          .dy;

      final dragItemBottom = dragItemTop + draggedItemHeight;

      double delta;
      if (dragItemTop <= 0) {
        delta = dragItemTop;
      } else if (dragItemBottom >= _listHeight) {
        delta = dragItemBottom - _listHeight;
      }

      if (delta != null) {
        final atTop = dragItemTop <= 0;
        delta = (delta.abs() / draggedItemHeight).clamp(0.1, 1.0);

        const maxSpeed = 20;
        final max = atTop ? -maxSpeed : maxSpeed;
        final scrollDelta = max * delta;

        controller.jumpTo(_offset + scrollDelta);
        onDragUpdated(_pointerDelta);
      }
    });
  }

  void onDragEnded() {
    if (dragKey == null || closestList.isEmpty) return;

    if (getTranslation(closest.key) == 0.0) {
      _dispatchMove(closest.key, up ? draggedItemHeight : -draggedItemHeight);
    }

    _onDragEnd = () {
      if (dragIndex != null) {
        final toIndex = _itemBoxes[closest.key].index;

        if (toIndex != dragIndex) {
          final item = dataSet.removeAt(dragIndex);
          dataSet.insert(toIndex, item);

          widget.onReorderFinished?.call(
            item,
            dragIndex,
            toIndex,
            List<E>.from(dataSet),
          );
        }
      }

      _cancelDrag();
    };

    final delta = closest != dragItem ? closest.top - (dragItem.top + _dragDelta) : -_pointerDelta;

    _dispatchMove(
      dragKey,
      // Make sure not to pass a zero delta (i.e. the item didn't move)
      // as this would lead to the same upper and lower bound on the animation
      // controller, which is not allowed.
      delta != 0.0 ? delta : 0.5,
      onEnd: _onDragEnd,
    );

    _scrollAdjuster?.cancel();

    // jumpTo() disposes of the current drag event which
    // Scrollable expects us to do.
    controller.jumpTo(controller.offset);

    setState(() => inDrag = false);
  }

  void _cancelDrag() {
    setState(() {
      _onDragEnd = null;
      _pointerDelta = 0.0;
      _dragDelta = 0.0;
      dragItem = null;
      _dragWidget = null;

      for (final key in _itemTranslations.keys) {
        _items[key]?.setTranslation(null);
      }

      _itemTranslations.clear();
    });
  }

  double getTranslation(Key key) => key == dragKey ? _dragDelta : _itemTranslations[key]?.value ?? 0.0;

  void registerItem(ReorderableState item) {
    _items[item.key] = item;
  }

  Offset _itemOffset(Key key) {
    final topRenderBox = context.renderBox;
    return _items[key]?.context?.renderBox?.localToGlobal(
          Offset.zero,
          ancestor: topRenderBox,
        );
  }

  bool _prevInDrag = false;

  void _onRebuild() {
    _itemBoxes.clear();

    final needsRebuild = _listHeight == 0 || inDrag != _prevInDrag;
    _prevInDrag = inDrag;

    postFrame(() {
      _listHeight = listKey.height;

      if (needsRebuild) setState(() {});
    });
  }

  void _measureItem(Reorderable child, int index) {
    postFrame(() {
      final key = child.key;
      final box = _items[key].context?.renderBox;
      final offset = _itemOffset(key)?.translate(0, _offset);

      if (box != null && offset != null) {
        _itemBoxes[key] = _Item(key, box, index, offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _onRebuild();

    return Stack(
      children: <Widget>[
        AnimatedList(
          key: listKey,
          itemBuilder: (context, index, animation) {
            final item = dataSet[index];

            final Reorderable child = buildItem(context, animation, item, index);
            _measureItem(child, index);

            if (dragKey != null && index == dragIndex) {
              final size = dragItem?.size;
              // Determine if the dragged widget should be hidden
              // immidiately, or with on frame delay in order to
              // avoid item flash.
              final mustRebuild = _dragWidget == null;

              _dragWidget = child;
              if (mustRebuild) postFrame(() => setState(() {}));

              // The placeholder of the dragged item.
              //
              // Make sure not to use the actual widget but only its size
              // when they have been determined, as a widget is only allowed
              // to be laid out once.
              return Invisible(
                invisible: !mustRebuild,
                child: mustRebuild ? child : SizedBox.fromSize(size: size),
              );
            }

            return child;
          },
          controller: controller,
          initialItemCount: newData.length,
          padding: widget.padding,
          physics: !inDrag ? widget.physics : const NeverScrollableScrollPhysics(),
          primary: widget.primary,
          reverse: widget.reverse,
          scrollDirection: widget.scrollDirection,
          shrinkWrap: widget.shrinkWrap,
        ),
        if (_dragWidget != null) _buildDraggedItem()
      ],
    );
  }

  Widget _buildDraggedItem() {
    return ValueListenableBuilder<double>(
      child: _dragWidget,
      valueListenable: _pointerDeltaNotifier,
      builder: (context, pointer, dragWidget) {
        final dy = _dragStartDy + pointer;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            key: _dragKey,
            child: dragWidget,
          ),
        );
      },
    );
  }

  static ImplicitlyAnimatedReorderableListState of(BuildContext context) {
    return context.findAncestorStateOfType<ImplicitlyAnimatedReorderableListState>();
  }

  @override
  void dispose() {
    _scrollAdjuster?.cancel();
    controller?.dispose();
    // _itemTranslations.forEach((key, controller) => controller?.dispose());
    super.dispose();
  }
}

// A class that holds meta information about items in the list such as position and size.
class _Item extends Rect implements Comparable<_Item> {
  final RenderBox box;
  final Key key;
  final int index;
  final Offset offset;
  _Item(
    this.key,
    this.box,
    this.index,
    this.offset,
  ) : super.fromLTWH(
          offset.dx,
          offset.dy,
          box.size.width,
          box.size.height,
        );

  double distance;

  @override
  int compareTo(_Item other) => distance != null && other.distance != null ? distance.compareTo(other.distance) : -1;

  @override
  String toString() => '_Item key: $key, index: $index';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _Item && o.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}