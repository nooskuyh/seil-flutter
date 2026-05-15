import 'package:flutter_test/flutter_test.dart';
import 'package:seil_mobile/shared/reconnect_policy.dart';

void main() {
  test('allows first reconnect attempt immediately', () {
    final policy = ReconnectPolicy();

    expect(policy.canAttempt('server-a'), isTrue);
    expect(policy.delayUntilNextAttempt(['server-a']), Duration.zero);
  });

  test('blocks automatic attempts until backoff delay passes', () {
    var now = DateTime.utc(2026, 5, 15, 12);
    final policy = ReconnectPolicy(clock: () => now);

    final failure = policy.recordFailure('server-a', StateError('offline'));

    expect(failure.attempts, 1);
    expect(failure.nextRetryAt, DateTime.utc(2026, 5, 15, 12, 0, 1));
    expect(policy.canAttempt('server-a'), isFalse);
    expect(
        policy.delayUntilNextAttempt(['server-a']), const Duration(seconds: 1));

    now = now.add(const Duration(seconds: 1));

    expect(policy.canAttempt('server-a'), isTrue);
    expect(policy.delayUntilNextAttempt(['server-a']), Duration.zero);
  });

  test('requires manual retry after max automatic failures', () {
    var now = DateTime.utc(2026, 5, 15, 12);
    final policy = ReconnectPolicy(
      clock: () => now,
      maxAutoAttempts: 2,
      backoffDelays: const [Duration(seconds: 1)],
    );

    policy.recordFailure('server-a', StateError('offline'));
    now = now.add(const Duration(seconds: 1));
    final failure = policy.recordFailure('server-a', StateError('offline'));

    expect(failure.requiresManualRetry, isTrue);
    expect(failure.nextRetryAt, isNull);
    expect(policy.canAttempt('server-a'), isFalse);
    expect(policy.canAttempt('server-a', force: true), isTrue);
    expect(policy.delayUntilNextAttempt(['server-a']), isNull);
  });

  test('marks selected failures as manual retry immediately', () {
    final policy = ReconnectPolicy();

    final failure = policy.recordFailure(
      'server-a',
      StateError('missing secret'),
      requiresManualRetry: true,
    );

    expect(failure.requiresManualRetry, isTrue);
    expect(policy.canAttempt('server-a'), isFalse);
  });

  test('clears failure state after success', () {
    final policy = ReconnectPolicy();

    policy.recordFailure('server-a', StateError('offline'));
    policy.recordSuccess('server-a');

    expect(policy.failureFor('server-a'), isNull);
    expect(policy.canAttempt('server-a'), isTrue);
  });
}
