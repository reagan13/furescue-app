import 'package:flutter/material.dart';

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

  static const _pages = [
    CasesListScreen(),
    LearningListScreen(),
    MessagesListScreen(),
    AccountTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
