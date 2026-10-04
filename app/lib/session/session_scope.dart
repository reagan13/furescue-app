import 'package:flutter/widgets.dart';

import 'auth_session.dart';

class SessionScope extends InheritedNotifier<AuthSession> {
  const SessionScope({
    super.key,
    required AuthSession session,
    required super.child,
  }) : super(notifier: session);

  static AuthSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found');
    return scope!.notifier!;
  }
}
