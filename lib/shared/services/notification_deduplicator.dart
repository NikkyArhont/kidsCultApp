import 'dart:collection';

/// Bounded per-session event IDs. Missing IDs must not collapse unrelated pushes.
class NotificationDeduplicator {
  NotificationDeduplicator({this.capacity = 200}) : assert(capacity > 0);

  final int capacity;
  final LinkedHashSet<String> _ids = LinkedHashSet<String>();

  bool accept(String? id) {
    if (id == null || id.isEmpty) return true;
    if (!_ids.add(id)) return false;
    if (_ids.length > capacity) _ids.remove(_ids.first);
    return true;
  }

  void clear() => _ids.clear();
}
