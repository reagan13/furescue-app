import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_client.dart';
import 'api/config.dart';
import 'screens/admin_blocked_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rescuer_shell.dart';
import 'screens/resident_shell.dart';
import 'session/auth_session.dart';
import 'session/session_scope.dart';
import 'session/session_store.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

class FuRescueApp extends StatefulWidget {
  const FuRescueApp({
    super.key,
    this.api,
    this.store,
    this.skipRestore = false,
  });

  final ApiClient? api;
  final SessionStore? store;
  final bool skipRestore;

  @override
  State<FuRescueApp> createState() => _FuRescueAppState();
}

class _FuRescueAppState extends State<FuRescueApp> {
  late final AuthSession _session;

  @override
  void initState() {
    super.initState();
    _session = AuthSession(
      api: widget.api ?? ApiClient(config: ApiConfig.current),
      store: widget.store ?? SecureSessionStore(),
    );
    if (widget.skipRestore) {
      _session.booting = false;
    } else {
      _session.restore();
    }
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.light;
    return SessionScope(
      session: _session,
      child: MaterialApp(
        title: 'FuRescue',
        debugShowCheckedModeBanner: false,
        theme: buildFuRescueTheme(tokens),
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: tokens.systemUi,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => _Gate(session: _session),
        ),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (session.booting) {
      return const _BootScreen();
    }
    if (!session.isSignedIn) {
      return const LoginScreen();
    }
    final user = session.user!;
    if (user.isAdmin) {
      return const AdminBlockedScreen();
    }
    if (user.isRescuer) {
      return const RescuerShell();
    }
    return const ResidentShell();
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.light;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: Center(child: CircularProgressIndicator(color: tokens.jungle)),
    );
  }
}
