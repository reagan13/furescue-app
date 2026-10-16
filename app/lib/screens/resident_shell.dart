import 'package:flutter/material.dart';

import '../inbox/inbox_watch.dart';
import '../offline/report_outbox.dart';
import '../session/session_scope.dart';
import '../widgets/confirm_action.dart';
import '../widgets/shell_header.dart';
import 'account_tab.dart';
import 'animals_list_screen.dart';
import 'learning_list_screen.dart';
import 'report_form_screen.dart';
import 'reports_list_screen.dart';

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key});

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell>
    with WidgetsBindingObserver {
  var _index = 0;
  ReportOutbox? _outbox;

  static const _titles = ['Reports', 'Browse', 'Report', 'Learn', 'Account'];

  static const _pages = [
    ReportsListScreen(),
    AnimalsListScreen(showAppBar: false),
    ReportFormScreen(),
    LearningListScreen(),
    AccountTab(showResidentLinks: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openOutbox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _flush();
    }
  }

  Future<void> _openOutbox() async {
    final box = await ReportOutbox.open();
    if (!mounted) {
      return;
    }
    setState(() => _outbox = box);
    await _flush();
  }

  Future<void> _flush() async {
    final box = _outbox;
    if (box == null || !mounted) {
      return;
    }
    final result = await box.flush(SessionScope.of(context).api);
    if (!mounted || result.sent == 0) {
      return;
    }
    final note = result.note;
    showSnack(
      context,
      note == null || note.isEmpty
          ? 'Sent ${result.sent} saved report${result.sent == 1 ? '' : 's'}.'
          : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = InboxScope.maybeOf(context)?.unread ?? 0;
    final body = Scaffold(
      appBar: ShellHeader(title: _titles[_index]),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Browse',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'Report',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: _accountIcon(selected: false, unread: unread),
            selectedIcon: _accountIcon(selected: true, unread: unread),
            label: 'Account',
          ),
        ],
      ),
    );
    final outbox = _outbox;
    if (outbox == null) {
      return body;
    }
    return ReportOutboxScope(outbox: outbox, child: body);
  }
}

Widget _accountIcon({required bool selected, required int unread}) {
  final icon = Icon(selected ? Icons.person : Icons.person_outline);
  if (unread <= 0) {
    return icon;
  }
  return Badge(label: Text(unread > 9 ? '9+' : '$unread'), child: icon);
}
