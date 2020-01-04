import 'package:flutter/material.dart';

import 'src.dart';

class ImplicitlyAnimatedList<E> extends ImplicitlyAnimatedListBase<Widget, E> {
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

  const ImplicitlyAnimatedList({
    Key key,
    @required List<E> data,
    @required AnimatedItemBuilder<Widget, E> itemBuilder,
    @required ItemDiffUtil<E> areItemsTheSame,
    RemovedItemBuilder<Widget, E> removedItemBuilder,
    UpdatedItemBuilder<Widget, E> updatedItemBuilder,
    Duration insertDuration = const Duration(milliseconds: 500),
    Duration removeDuration = const Duration(milliseconds: 500),
    Duration updateDuration = const Duration(milliseconds: 500),
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  })  : assert(itemBuilder != null),
        assert(areItemsTheSame != null),
        assert(data != null),
        super(
          key: key,
          data: data,
          itemBuilder: itemBuilder,
          areItemsTheSame: areItemsTheSame,
          removedItemBuilder: removedItemBuilder,
          updatedItemBuilder: updatedItemBuilder,
          insertDuration: insertDuration,
          removeDuration: removeDuration,
          updateDuration: updateDuration,
        );

  @override
  ImplicitlyAnimatedListState<E> createState() => ImplicitlyAnimatedListState<E>();
}

class ImplicitlyAnimatedListState<E> extends ImplicitlyAnimatedListBaseState<Widget, ImplicitlyAnimatedList<E>, E> {
  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      itemBuilder: (context, index, animation) {
        final item = dataSet[index];

        Widget child;
        if (widget.updatedItemBuilder != null && changes[item] != null) {
          child = buildUpdatedItemWidget(item);
        } else {
          child = itemBuilder(context, animation, item, index);
        }

        return child;
      },
      controller: widget.controller,
      initialItemCount: newData.length,
      padding: widget.padding,
      physics: widget.physics,
      primary: widget.primary,
      reverse: widget.reverse,
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
    );
  }
}
