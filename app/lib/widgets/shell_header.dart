import 'package:flutter/material.dart';

import '../inbox/inbox_watch.dart';
import '../screens/messages_list_screen.dart';
import '../screens/notifications_screen.dart';
import '../theme/tokens.dart';

/// Top bar for shells and pushed screens. Title, bell, and messages stay
/// the same chrome; [showBack] adds a leading back button on nested routes.
class ShellHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShellHeader({super.key, required this.title, this.showBack = false});

  final String title;

  /// True on pushed screens. Tab roots keep the bar without a back button.
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final unread = InboxScope.maybeOf(context)?.unread ?? 0;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack ? const BackButton() : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _open(context, const NotificationsScreen()),
          icon: _bell(unread),
        ),
        IconButton(
          tooltip: 'Messages',
          onPressed: () => _open(context, const MessagesListScreen()),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: tokens.border),
      ),
    );
  }

  Widget _bell(int unread) {
    const icon = Icon(Icons.notifications_outlined);
    if (unread <= 0) {
      return icon;
    }
    return Badge(label: Text(unread > 9 ? '9+' : '$unread'), child: icon);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
