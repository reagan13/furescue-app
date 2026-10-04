import 'package:flutter/material.dart';

import '../api/config.dart';
import '../api/media.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_action.dart';
import 'account_edit_screen.dart';
import 'adoptions_list_screen.dart';
import 'feedback_screen.dart';
import 'listings_list_screen.dart';
import 'messages_list_screen.dart';
import 'notifications_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key, this.showResidentLinks = false});

  final bool showResidentLinks;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    final tokens = context.tokens;
    final photo = user?.profilePhotoUrl;
    final photoUrl = photo == null || photo.isEmpty
        ? null
        : resolveMediaUrl(ApiConfig.current, photo);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: tokens.muted,
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null
                      ? Icon(
                          Icons.person_outline,
                          color: tokens.jungle,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.role ?? '',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: tokens.jungle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.phoneNumber!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (user?.isRescuer == true) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duty',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.isOnDuty
                              ? 'On duty — admin can assign cases'
                              : 'Off duty',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: session.isOnDuty,
                    onChanged: (on) async {
                      final next = on ? 'on_duty' : 'off_duty';
                      final ok = await confirmAction(
                        context,
                        title: on ? 'Go on duty?' : 'Go off duty?',
                        message: on
                            ? 'This will update your rescuer duty status to on duty.'
                            : 'This will update your rescuer duty status to off duty.',
                        confirmLabel: on ? 'Go on duty' : 'Go off duty',
                      );
                      if (!ok || !context.mounted) {
                        return;
                      }
                      try {
                        await session.setDuty(next);
                      } catch (e) {
                        if (context.mounted) {
                          showSnack(context, e.toString());
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _LinkTile(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountEditScreen(),
                ),
              );
            },
          ),
          if (showResidentLinks) ...[
            _LinkTile(
              icon: Icons.favorite_outline,
              title: 'My adoptions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdoptionsListScreen(),
                  ),
                );
              },
            ),
            _LinkTile(
              icon: Icons.campaign_outlined,
              title: 'My listings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ListingsListScreen(),
                  ),
                );
              },
            ),
            _LinkTile(
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MessagesListScreen(),
                  ),
                );
              },
            ),
          ],
          _LinkTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _LinkTile(
            icon: Icons.flag_outlined,
            title: 'Report a problem',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FeedbackScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: session.logout,
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: context.tokens.jungle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(Icons.chevron_right, color: context.tokens.stamp),
          ],
        ),
      ),
    );
  }
}
