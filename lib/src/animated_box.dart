import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

enum ShadowDirection {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  center,
}

class BoxTransition extends StatefulWidget {
  final double borderRadius;
  final double elevation;
  final double height;
  final double width;
  final Border border;
  final BorderRadius customBorders;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final List<BoxShadow> boxShadows;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  final AlignmentGeometry alignment;
  final ShadowDirection shadowDirection;
  final Color splashColor;
  final Color hoverColor;
  final Color focusColor;
  final Color hightLightColor;
  final Animation<double> animation;
  BoxTransition({
    Key key,
    @required this.animation,
    @required this.child,
    this.border,
    this.color = Colors.transparent,
    this.borderRadius = 0.0,
    this.elevation = 0.0,
    this.splashColor,
    this.focusColor,
    this.hightLightColor,
    this.hoverColor,
    this.shadowColor = Colors.black12,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.height,
    this.width,
    this.margin,
    this.customBorders,
    this.alignment,
    this.boxShadows,
    this.shadowDirection = ShadowDirection.bottomRight,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  _BoxTransitionState createState() => _BoxTransitionState();
}

class _BoxTransitionState extends State<BoxTransition> {
  double height;
  double width;
  Color color;
  Border border;
  BorderRadius borderRadius;
  double elevation;
  Color splashColor;
  Color hoverColor;
  Color focusColor;
  Color hightLightColor;
  Color shadowColor;
  Alignment alignment;
  List<BoxShadow> boxShadows;
  EdgeInsets padding;
  EdgeInsets margin;
  Animation<double> get animation => widget.animation;

  @override
  void initState() {
    super.initState();

    height = widget.height;
    width = widget.width;
    color = widget.color;
    border = widget.border;
    borderRadius = widget.customBorders ?? BorderRadius.circular(widget.borderRadius ?? 0.0);
    elevation = widget.elevation;
    splashColor = widget.splashColor;
    hoverColor = widget.hoverColor;
    focusColor = widget.focusColor;
    hightLightColor = widget.hightLightColor;
    shadowColor = widget.shadowColor;
    alignment = widget.alignment;
    boxShadows = widget.boxShadows;
    padding = widget.padding;
    margin = widget.margin;
  }

  VoidCallback _tick;

  @override
  void didUpdateWidget(BoxTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldHeight = height;
    final oldWidth = width;
    final oldElevation = elevation;
    final oldColor = color != null ? Color(color.value) : null;
    final oldBorder = border?.lerpTo(border, 1.0);
    final oldBorderRadius = borderRadius != null ? BorderRadius.lerp(null, borderRadius, 1.0) : null;
    final oldSplashColor = splashColor != null ? Color(splashColor.value) : null;
    final oldHoverColor = hoverColor != null ? Color(hoverColor.value) : null;
    final oldFocusColor = focusColor != null ? Color(focusColor.value) : null;
    final oldHighLightColor = hightLightColor != null ? Color(hightLightColor.value) : null;
    final oldShadowColor = shadowColor != null ? Color(shadowColor.value) : null;
    final oldAlignment = alignment != null ? Alignment(alignment.x, alignment.y) : null;
    final oldBoxShadows = boxShadows != null ? List<BoxShadow>.from(boxShadows) : null;
    final oldPadding = padding?.copyWith();
    final oldMargin = margin?.copyWith();

    _tick = () {
      final v = animation.value;
      height = lerpDouble(oldHeight, widget.height, v);
      width = lerpDouble(oldWidth, widget.width, v);
      elevation = lerpDouble(oldElevation, widget.elevation, v);
      border = Border.lerp(oldBorder, widget.border, v);
      borderRadius = BorderRadius.lerp(
        oldBorderRadius,
        widget.customBorders ?? BorderRadius.circular(widget.borderRadius ?? 0.0),
        v,
      );
      color = Color.lerp(oldColor, widget.color, v);
      splashColor = Color.lerp(oldSplashColor, widget.splashColor, v);
      focusColor = Color.lerp(oldFocusColor, widget.focusColor, v);
      hoverColor = Color.lerp(oldHoverColor, widget.hoverColor, v);
      hightLightColor = Color.lerp(oldHighLightColor, widget.hightLightColor, v);
      shadowColor = Color.lerp(oldShadowColor, widget.shadowColor, v);
      alignment = Alignment.lerp(oldAlignment, widget.alignment, v);
      boxShadows = BoxShadow.lerpList(oldBoxShadows, widget.boxShadows, v);
      padding = EdgeInsets.lerp(oldPadding, widget.padding, v);
      margin = EdgeInsets.lerp(oldMargin, widget.margin, v);

      if (mounted) {
        setState(() {});
      }
    };

    animation.addListener(_tick);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = width;
    final h = height;

    Widget content = Padding(
      padding: padding,
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null || widget.onDoubleTap != null) {
      content = Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          splashColor: splashColor ?? theme.splashColor,
          highlightColor: theme.highlightColor,
          hoverColor: hoverColor ?? theme.hoverColor,
          focusColor: focusColor ?? theme.focusColor,
          customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onDoubleTap: widget.onDoubleTap,
          child: content,
        ),
      );
    }

    final List<BoxShadow> boxShadow = boxShadows ?? (elevation > 0 && (shadowColor?.opacity ?? 0) > 0)
        ? [
            BoxShadow(
              color: shadowColor ?? Colors.black12,
              offset: _getShadowOffset(min(elevation / 5.0, 1.0)),
              blurRadius: elevation,
              spreadRadius: 0,
            ),
          ]
        : null;

    final boxDecoration = BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      border: border,
    );

    return Container(
      height: h,
      width: w,
      margin: margin,
      alignment: alignment,
      decoration: boxDecoration,
      child: content,
    );
  }

  Offset _getShadowOffset(double ele) {
    final ym = 5 * ele;
    final xm = 2 * ele;
    switch (widget.shadowDirection) {
      case ShadowDirection.topLeft:
        return Offset(-1 * xm, -1 * ym);
      case ShadowDirection.top:
        return Offset(0, -1 * ym);
      case ShadowDirection.topRight:
        return Offset(xm, -1 * ym);
      case ShadowDirection.right:
        return Offset(xm, 0);
      case ShadowDirection.bottomRight:
        return Offset(xm, ym);
      case ShadowDirection.bottom:
        return Offset(0, ym);
      case ShadowDirection.bottomLeft:
        return Offset(-1 * xm, ym);
      case ShadowDirection.left:
        return Offset(-1 * xm, 0);
      default:
        return Offset.zero;
    }
  }

  @override
  void dispose() {
    animation.removeListener(_tick);
    super.dispose();
  }
}
