import 'package:async/async.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'src.dart';

typedef AnimatedItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, Animation<double> animation, E item, int i);

typedef RemovedItemBuilder<W extends Widget, E> = W Function(BuildContext context, Animation<double> animation, E item);

typedef UpdatedItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, Animation<double> animation, E item);

abstract class ImplicitlyAnimatedListBase<W extends Widget, E> extends StatefulWidget {
  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  final AnimatedItemBuilder<W, E> itemBuilder;

  /// An optional builder when an item was removed from the list.
  ///
  /// If not specified, the [ImplicitlyAnimatedList] uses the [itemBuilder] with
  /// the animation reversed.
  final RemovedItemBuilder<W, E> removeItemBuilder;

  /// An optional builder when an item in the list was changed but not its position.
  ///
  /// The [UpdatedItemBuilder] animation will run from 1 to 0 and back to 1 again, while
  /// the item parameter will be the old item in the first half of the animation and the new item
  /// in the latter half of the animation. This allows you for example to fade between the old and
  /// the new item.
  ///
  /// If not specified, changes will appear instantaneously.
  final UpdatedItemBuilder<W, E> updateItemBuilder;

  /// The data that this [ImplicitlyAnimatedList] should represent.
  final List<E> items;

  /// Called by the DiffUtil to decide whether two object represent the same Item.
  /// For example, if your items have unique ids, this method should check their id equality.
  final ItemDiffUtil<E> areItemsTheSame;

  /// The duration of the animation when an item was inserted into the list.
  final Duration insertDuration;

  /// The duration of the animation when an item was removed from the list.
  final Duration removeDuration;

  /// The duration of the animation when an item changed in the list.
  final Duration updateDuration;
  const ImplicitlyAnimatedListBase({
    Key key,
    @required this.items,
    @required this.areItemsTheSame,
    @required this.itemBuilder,
    @required this.removeItemBuilder,
    @required this.updateItemBuilder,
    @required this.insertDuration,
    @required this.removeDuration,
    @required this.updateDuration,
  }) : super(key: key);
}

abstract class ImplicitlyAnimatedListBaseState<W extends Widget, B extends ImplicitlyAnimatedListBase<W, E>, E>
    extends State<B> with DiffCallback<E>, TickerProviderStateMixin {
  GlobalKey<AnimatedListState> listKey;
  AnimatedListState get list => listKey.currentState;

  AnimatedItemBuilder<W, E> get itemBuilder => widget.itemBuilder;
  RemovedItemBuilder<W, E> get removeItemBuilder => widget.removeItemBuilder;
  UpdatedItemBuilder<W, E> get updateItemBuilder => widget.updateItemBuilder;

  DiffDelegate _delegate;
  CancelableOperation _differ;

  // Animation controller for custom animation that are not supported
  // by the [AnimatedList], like updates.
  AnimationController _animController;
  Animation<double> updateAnimation;

  List<E> dataSet;
  List<E> newData;
  List<E> oldData;

  Map<E, E> changes = {};

  @nonVirtual
  @protected
  @override
  List<E> get newList => newData;

  @nonVirtual
  @protected
  @override
  List<E> get oldList => oldData;

  @override
  void initState() {
    super.initState();
    listKey = GlobalKey();
    dataSet = List<E>.from(widget.items);
    _delegate = DiffDelegate(this);

    _animController = AnimationController(vsync: this);
    updateAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 0.5,
      ),
    ]).animate(_animController);

    // _scrollController = widget.controller ?? ScrollController();

    didUpdateWidget(widget);
  }

  @override
  void didUpdateWidget(ImplicitlyAnimatedListBase oldWidget) {
    super.didUpdateWidget(oldWidget);

    newData = List<E>.from(widget.items);
    oldData = List<E>.from(dataSet);

    _animController.duration = widget.updateDuration;

    _calcDiffs();
  }

  void _calcDiffs() async {
    if (!listEquals(oldData, newData)) {
      changes.clear();

      await _differ?.cancel();
      _differ = CancelableOperation.fromFuture(
        DiffUtil.calculateDiff<E>(this),
      );

      final diffs = await _differ.value;
      if (diffs == null) return;
      _delegate.applyDiffs(diffs);

      _animController
        ..reset()
        ..forward();
    }
  }

  @nonVirtual
  @protected
  @override
  bool areContentsTheSame(E oldItem, E newItem) => true;

  @nonVirtual
  @protected
  @override
  bool areItemsTheSame(E oldItem, E newItem) => widget.areItemsTheSame(oldItem, newItem);

  @nonVirtual
  @protected
  @override
  void onInserted(int index, E item) {
    // print('Inserted $item at $index');
    dataSet.insert(index, item);
    list.insertItem(index, duration: widget.insertDuration);
  }

  @nonVirtual
  @protected
  @override
  void onRemoved(int index) {
    final item = dataSet.removeAt(index);
    // print('Removed $item at $index');
    list.removeItem(index, (context, animation) {
      if (removeItemBuilder != null) {
        return removeItemBuilder(context, animation, item);
      }

      return itemBuilder(context, animation, item, index);
    }, duration: widget.removeDuration);
  }

  @nonVirtual
  @protected
  @override
  void onChanged(int startIndex, List<E> itemsChanged) {
    int i = 0;
    for (final item in itemsChanged) {
      // print('Changed $item');
      final index = startIndex + i;
      changes[item] = dataSet[index];
      dataSet[index] = item;
      i++;
    }

    setState(() {});
  }

  @nonVirtual
  @protected
  Widget buildItem(BuildContext context, Animation<double> animation, E item, int index) {
    if (widget.updateItemBuilder != null && changes[item] != null) {
      return buildUpdatedItemWidget(item);
    }

    return itemBuilder(context, animation, item, index);
  }

  @nonVirtual
  @protected
  Widget buildUpdatedItemWidget(E newItem) {
    final oldItem = changes[newItem];

    return AnimatedBuilder(
      animation: updateAnimation,
      builder: (context, _) {
        final value = _animController.value;
        final item = value < 0.5 ? oldItem : newItem;

        return updateItemBuilder(
          context,
          updateAnimation,
          item,
        );
      },
    );
  }
}