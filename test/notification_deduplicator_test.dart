import 'package:child_tracker/shared/services/notification_deduplicator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foreground delivery does not consume the later tap', () {
    final delivered = NotificationDeduplicator();
    final opened = NotificationDeduplicator();
    expect(delivered.accept('message-1'), isTrue);
    expect(delivered.accept('message-1'), isFalse);
    expect(opened.accept('message-1'), isTrue);
    expect(opened.accept('message-1'), isFalse);
  });

  test('messages without IDs remain independent', () {
    final cache = NotificationDeduplicator();
    expect(cache.accept(null), isTrue);
    expect(cache.accept(null), isTrue);
    expect(cache.accept(''), isTrue);
    expect(cache.accept(''), isTrue);
  });

  test('bounded IDs expire in arrival order and are cleared between sessions', () {
    final cache = NotificationDeduplicator(capacity: 2);
    expect(cache.accept('first'), isTrue);
    expect(cache.accept('second'), isTrue);
    expect(cache.accept('third'), isTrue);
    expect(cache.accept('second'), isFalse);
    expect(cache.accept('first'), isTrue);
    cache.clear();
    expect(cache.accept('first'), isTrue);
  });
}
