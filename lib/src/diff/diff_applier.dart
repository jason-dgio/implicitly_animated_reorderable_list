import 'diff.dart';

class DiffApplier<E> {
  final DiffCallback<E> _callback;
  const DiffApplier(this._callback);

  void applyDiffs(List<Diff> diffs) {
    for (final diff in diffs) {
      if (diff is Insertion) {
        _applyInsertion(diff as Insertion<E>);
      } else if (diff is Deletion) {
        _applyDeletion(diff);
      } else if (diff is Modification) {
        _applyModification(diff as Modification<E>);
      }
    }
  }

  void _applyModification(Modification<E> diff) {
    if (diff.size > diff.items.length) {
      int sizeDifference = diff.size - diff.items.length;
      while (sizeDifference > 0) {
        _callback.onRemoved(diff.index + sizeDifference);
        sizeDifference--;
      }
    } else if (diff.items.length > diff.size) {
      int insertIndex = diff.size;
      while (insertIndex < diff.items.length) {
        _callback.onInserted(insertIndex + diff.index, diff.items[insertIndex]);
        insertIndex++;
      }
    }

    final changedItems = diff.items.take(diff.size).toList();
    _callback.onChanged(diff.index, changedItems);
  }

  void _applyDeletion(Deletion diff) {
    for (int i = 0; i < diff.size; i++) {
      _callback.onRemoved(diff.index);
    }
  }

  void _applyInsertion(Insertion<E> diff) {
    for (int i = 0; i < diff.size; i++) {
      _callback.onInserted(diff.index + i, diff.items[i]);
    }
  }
}