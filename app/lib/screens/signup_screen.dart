import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/auth_field.dart';
import '../widgets/brand_mark.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  var _role = 'resident';
  var _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullName.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (fullName.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() => _error = null);
    try {
      final pending = await SessionScope.of(context).register(
        fullName: fullName,
        email: email,
        password: password,
        role: _role,
        phoneNumber: _phone.text,
        address: _address.text,
      );
      if (!mounted) {
        return;
      }
      if (pending != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(pending)));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendly(e));
    }
  }

  String _friendly(ApiException e) {
    if (e.code == 'EMAIL_TAKEN') {
      return 'That email is already registered. Try signing in instead.';
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const BrandMark(compact: true),
            const SizedBox(height: 12),
            Text(
              'Sign up in seconds — rescuer accounts are reviewed by an admin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            AuthField(
              label: 'Full name',
              controller: _fullName,
              hint: 'Juan Dela Cruz',
              autofillHints: const [AutofillHints.name],
              maxLength: 150,
            ),
            const SizedBox(height: 16),
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
              hint: 'At least 8 characters',
              obscure: _hidePassword,
              onToggleObscure: () =>
                  setState(() => _hidePassword = !_hidePassword),
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'Phone (optional)',
              controller: _phone,
              hint: '09XX XXX XXXX',
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            Text(
              'I want to join as',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _role,
              items: const [
                DropdownMenuItem(value: 'resident', child: Text('Resident')),
                DropdownMenuItem(value: 'rescuer', child: Text('Rescuer')),
              ],
              onChanged: session.busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _role = value);
                      }
                    },
            ),
            if (_role == 'rescuer') ...[
              const SizedBox(height: 12),
              Text(
                'Your account will require admin approval before you can respond to rescues.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            AuthField(
              label: 'Address (optional)',
              controller: _address,
              hint: 'Barangay, City of Mati',
              autofillHints: const [AutofillHints.streetAddressLine1],
              maxLength: 1000,
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
                  : const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
