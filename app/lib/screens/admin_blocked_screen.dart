import 'package:flutter/material.dart';

import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/brand_mark.dart';

class AdminBlockedScreen extends StatelessWidget {
  const AdminBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final tokens = context.tokens;
    final email = session.user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(),
              const Spacer(),
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 48,
                color: tokens.jungle,
              ),
              const SizedBox(height: 16),
              Text(
                'Use the web console',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Admin tools stay on the FuRescue website. This app is for residents and rescuers only.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Signed in as $email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: session.logout,
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
