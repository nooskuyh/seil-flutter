import 'package:flutter_test/flutter_test.dart';
import 'package:seil_mobile/shared/models.dart';

void main() {
  group('terminalAttentionFromTmux', () {
    test('detects running spinner from terminal title', () {
      expect(
        terminalAttentionFromTmux(
          terminalTitle: '⠋ Codex | Working | seil-flutter-public',
        ),
        TerminalAttentionState.running,
      );
    });

    test('detects action required title before running state', () {
      expect(
        terminalAttentionFromTmux(
          terminalTitle: '[ ! ] Action Required | Codex | project',
        ),
        TerminalAttentionState.actionRequired,
      );
    });

    test('detects completed state from tmux bell flag', () {
      expect(
        terminalAttentionFromTmux(windowBellFlag: '1'),
        TerminalAttentionState.completed,
      );
    });

    test('keeps generic activity out of completed state', () {
      expect(
        terminalAttentionFromTmux(
          windowFlags: '#',
          windowActivityFlag: '1',
        ),
        TerminalAttentionState.none,
      );
    });
  });

  test('maxTerminalAttentionState prefers actionable states', () {
    expect(
      maxTerminalAttentionState(
        TerminalAttentionState.completed,
        TerminalAttentionState.running,
      ),
      TerminalAttentionState.running,
    );
    expect(
      maxTerminalAttentionState(
        TerminalAttentionState.actionRequired,
        TerminalAttentionState.running,
      ),
      TerminalAttentionState.actionRequired,
    );
  });

  group('terminalAttentionFromTransition', () {
    test('marks title return from running as completed', () {
      expect(
        terminalAttentionFromTransition(
          previous: TerminalAttentionState.running,
          current: TerminalAttentionState.none,
        ),
        TerminalAttentionState.completed,
      );
    });

    test('keeps completed state until a new active state is observed', () {
      expect(
        terminalAttentionFromTransition(
          previous: TerminalAttentionState.completed,
          current: TerminalAttentionState.none,
        ),
        TerminalAttentionState.completed,
      );
    });

    test('new running state overrides previous completed state', () {
      expect(
        terminalAttentionFromTransition(
          previous: TerminalAttentionState.completed,
          current: TerminalAttentionState.running,
        ),
        TerminalAttentionState.running,
      );
    });
  });
}
