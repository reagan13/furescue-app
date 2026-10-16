import 'package:flutter/material.dart';

import '../inbox/inbox_watch.dart';
import '../widgets/shell_header.dart';
import 'account_tab.dart';
import 'cases_list_screen.dart';
import 'learning_list_screen.dart';
import 'messages_list_screen.dart';

class RescuerShell extends StatefulWidget {
  const RescuerShell({super.key});

  @override
  State<RescuerShell> createState() => _RescuerShellState();
}

class _RescuerShellState extends State<RescuerShell> {
  var _index = 0;

  static const _titles = ['Cases', 'Learn', 'Messages', 'Account'];

  static const _pages = [
    CasesListScreen(),
    LearningListScreen(),
    MessagesListScreen(showAppBar: false),
    AccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = InboxScope.maybeOf(context)?.unread ?? 0;
    final accountIcon = unread <= 0
        ? const Icon(Icons.person_outline)
        : Badge(
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.person_outline),
          );
    final accountSelected = unread <= 0
        ? const Icon(Icons.person)
        : Badge(
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.person),
          );
    return Scaffold(
      appBar: ShellHeader(title: _titles[_index]),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Cases',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: accountIcon,
            selectedIcon: accountSelected,
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
