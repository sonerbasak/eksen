import 'dart:io';
import 'package:git_hooks/git_hooks.dart';

void main(List<String> arguments) {
  final Map<Git, UserBackFun> params = {
    Git.commitMsg: commitMsg,
    Git.preCommit: preCommit,
  };
  GitHooks.call(arguments, params);
}

/// Validates commit message against the Conventional Commits specification.
/// Allowed types: feat, fix, docs, style, refactor, perf, test, chore, revert.
/// Format example: feat(auth): add google sign-in support
Future<bool> commitMsg() async {
  final rawMsg = Utils.getCommitEditMsg();
  final msg = rawMsg.trim();

  // Conventional Commits regex pattern
  final conventionalPattern = RegExp(
    r'^(feat|fix|docs|style|refactor|perf|test|chore|revert)(\([a-z0-9-_/.]+\))?!?: .+$',
  );

  if (!conventionalPattern.hasMatch(msg)) {
    stdout.writeln('\x1B[31m[ERROR] Invalid commit message format!\x1B[0m');
    stdout.writeln(
      'Commit message must follow Conventional Commits specification:\n'
      '  <type>(<optional scope>): <description>\n\n'
      'Examples:\n'
      '  feat(habit): add streak freeze calculation logic\n'
      '  fix(sync): resolve offline queue duplicate key error\n'
      '  chore: bump packages to latest compatible versions\n\n'
      'Allowed types: feat, fix, docs, style, refactor, perf, test, chore, revert',
    );
    return false;
  }

  return true;
}

/// Runs code formatting verification and static analysis before allowing the commit.
Future<bool> preCommit() async {
  stdout.writeln('\x1B[36m[PRE-COMMIT] Checking code formatting...\x1B[0m');

  // Verify that all Dart files follow standard formatting
  final formatResult = await Process.run('dart', [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'lib',
    'test',
  ]);

  if (formatResult.exitCode != 0) {
    stdout.writeln(
      '\x1B[31m[ERROR] Code formatting issues found! Run "dart format lib test" to fix them.\x1B[0m',
    );
    stdout.writeln(formatResult.stdout);
    return false;
  }

  stdout.writeln('\x1B[36m[PRE-COMMIT] Running Flutter analyzer...\x1B[0m');

  // Verify that there are no analyzer errors or critical warnings
  final analyzeResult = await Process.run('flutter', [
    'analyze',
    '--fatal-infos',
  ]);

  if (analyzeResult.exitCode != 0) {
    stdout.writeln(
      '\x1B[31m[ERROR] Static analysis checks failed!\x1B[0m',
    );
    stdout.writeln(analyzeResult.stdout);
    return false;
  }

  stdout.writeln('\x1B[32m[PRE-COMMIT] All checks passed successfully.\x1B[0m');
  return true;
}