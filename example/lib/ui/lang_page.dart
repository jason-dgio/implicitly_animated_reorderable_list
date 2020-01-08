import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

import '../animations/animations.dart';
import '../util/util.dart';
import 'search_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({
    Key key,
  }) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Language> selectedLanguages = [
    english,
    german,
    spanish,
  ];

  Widget _buildTile(Animation animation, Language lang, int index) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final t = animation.value;
    final color = Color.lerp(Colors.white, Colors.grey.shade100, t);
    final elevation = lerpDouble(0, 8, t);

    final List<Widget> actions = selectedLanguages.length > 1
        ? [
            SlideAction(
              closeOnTap: true,
              color: Colors.redAccent,
              onTap: () {
                setState(
                  () => selectedLanguages.remove(lang),
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: textTheme.body2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        : [];

    return Slidable(
      actionPane: SlidableBehindActionPane(),
      actions: actions,
      secondaryActions: actions,
      child: Box(
        color: color,
        elevation: elevation,
        child: ListTile(
          title: Text(
            lang.nativeName,
            style: textTheme.body2.copyWith(
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            lang.englishName,
            style: textTheme.body1.copyWith(
              fontSize: 15,
            ),
          ),
          leading: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '${index + 1}',
                style: textTheme.body2.copyWith(
                  color: theme.accentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          trailing: Handle(
            delay: const Duration(milliseconds: 100),
            child: Icon(
              Icons.list,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Languages Demo'),
        backgroundColor: theme.accentColor,
      ),
      body: ListView(
        children: <Widget>[
          ImplicitlyAnimatedReorderableList<Language>(
            shrinkWrap: true,
            items: selectedLanguages,
            areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
            onReorderFinished: (movedLanguage, from, to, newData) {
              // Update the underlying data when the item has been reordered
              setState(() {
                selectedLanguages
                  ..clear()
                  ..addAll(newData);
              });
            },
            itemBuilder: (context, itemAnimation, lang, index) {
              return Reorderable(
                key: ValueKey(lang),
                builder: (context, dragAnimation, inDrag) {
                  final tile = _buildTile(dragAnimation, lang, index);

                  // If the item is in drag, only return the tile as the
                  // SizeFadeTransition would clip the shadow.
                  if (inDrag) {
                    return tile;
                  }

                  // Specifiy an animation to be used.
                  return SizeFadeTranstion(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    animation: itemAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        tile,
                        Divider(height: 0),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Box(
            color: Colors.white,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LanguageSearchPage(),
                ),
              );

              if (result != null && !selectedLanguages.contains(result)) {
                selectedLanguages.add(result);
              }
            },
            child: ListTile(
              leading: SizedBox(
                height: 36,
                width: 36,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.grey,
                  ),
                ),
              ),
              title: Text(
                'Add a language',
                style: textTheme.body2.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
