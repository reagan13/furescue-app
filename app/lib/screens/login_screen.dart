import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/auth_field.dart';
import '../widgets/brand_mark.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() => _error = null);
    try {
      await SessionScope.of(context).login(email: email, password: password);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendly(e));
    }
  }

  String _friendly(ApiException e) {
    if (e.code == 'INVALID_CREDENTIALS') {
      return 'Email or password is incorrect.';
    }
    if (e.isPending) {
      return e.message;
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final tokens = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64)
                      .clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 8),
                    Text(
                      'Rescue. Protect. Love.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Log in',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resident and rescuer accounts only. Admin stays on the web console.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    AuthField(
                      label: 'Email',
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      label: 'Password',
                      controller: _password,
                      hint: 'Your password',
                      obscure: _hidePassword,
                      onToggleObscure: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: tokens.destructive),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: session.busy ? null : _submit,
                      child: session.busy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tokens.primaryForeground,
                              ),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: session.busy
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
