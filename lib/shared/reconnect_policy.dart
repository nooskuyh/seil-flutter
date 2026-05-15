class ReconnectPolicy {
  ReconnectPolicy({
    DateTime Function()? clock,
    this.maxAutoAttempts = 5,
    this.backoffDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 10),
      Duration(seconds: 30),
    ],
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final int maxAutoAttempts;
  final List<Duration> backoffDelays;
  final Map<String, ReconnectFailure> _failures = {};

  bool canAttempt(String key, {bool force = false}) {
    if (force) {
      return true;
    }
    final failure = _failures[key];
    if (failure == null) {
      return true;
    }
    if (failure.requiresManualRetry) {
      return false;
    }
    final nextRetryAt = failure.nextRetryAt;
    return nextRetryAt == null || !_clock().isBefore(nextRetryAt);
  }

  void recordSuccess(String key) {
    _failures.remove(key);
  }

  ReconnectFailure recordFailure(
    String key,
    Object error, {
    bool requiresManualRetry = false,
  }) {
    final previous = _failures[key];
    final attempts = (previous?.attempts ?? 0) + 1;
    final manualRetry = requiresManualRetry ||
        attempts >= maxAutoAttempts ||
        maxAutoAttempts <= 0;
    final failure = ReconnectFailure(
      attempts: attempts,
      failedAt: _clock(),
      nextRetryAt:
          manualRetry ? null : _clock().add(_delayForAttempt(attempts)),
      lastError: error,
      requiresManualRetry: manualRetry,
    );
    _failures[key] = failure;
    return failure;
  }

  void clear(String key) {
    _failures.remove(key);
  }

  void clearAll() {
    _failures.clear();
  }

  ReconnectFailure? failureFor(String key) => _failures[key];

  Duration? delayUntilNextAttempt(Iterable<String> keys) {
    DateTime? earliest;
    final now = _clock();
    for (final key in keys) {
      final failure = _failures[key];
      if (failure == null) {
        return Duration.zero;
      }
      if (failure.requiresManualRetry) {
        continue;
      }
      final nextRetryAt = failure.nextRetryAt;
      if (nextRetryAt == null || !now.isBefore(nextRetryAt)) {
        return Duration.zero;
      }
      if (earliest == null || nextRetryAt.isBefore(earliest)) {
        earliest = nextRetryAt;
      }
    }
    if (earliest == null) {
      return null;
    }
    final delay = earliest.difference(now);
    return delay.isNegative ? Duration.zero : delay;
  }

  Duration _delayForAttempt(int attempts) {
    if (backoffDelays.isEmpty) {
      return Duration.zero;
    }
    final index = (attempts - 1).clamp(0, backoffDelays.length - 1);
    return backoffDelays[index];
  }
}

class ReconnectFailure {
  const ReconnectFailure({
    required this.attempts,
    required this.failedAt,
    required this.nextRetryAt,
    required this.lastError,
    required this.requiresManualRetry,
  });

  final int attempts;
  final DateTime failedAt;
  final DateTime? nextRetryAt;
  final Object lastError;
  final bool requiresManualRetry;
}
