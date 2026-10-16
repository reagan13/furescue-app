import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/user.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/auth_field.dart';
import '../widgets/confirm_action.dart';
import '../widgets/shell_header.dart';

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  var _hydrated = false;
  var _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) {
      return;
    }
    final user = SessionScope.of(context).user;
    _name.text = user?.fullName ?? '';
    _phone.text = user?.phoneNumber ?? '';
    _address.text = user?.address ?? '';
    _hydrated = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    final id = session.user?.id;
    if (id == null) {
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = await session.api.patch(
        '/api/v1/users/$id',
        body: {
          'full_name': name,
          'phone_number': _phone.text.trim(),
          'address': _address.text.trim(),
        },
      );
      session.applyUser(User.fromJson(asJsonMap(data['user'])));
      if (mounted) {
        showSnack(context, 'Profile saved.');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  Future<void> _photo() async {
    final session = SessionScope.of(context);
    final id = session.user?.id;
    if (id == null) {
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await session.api.postMultipart(
        '/api/v1/users/$id/profile-photo',
        fieldName: 'file',
        filePaths: [file.path],
      );
      session.applyUser(User.fromJson(asJsonMap(data['user'])));
      if (mounted) {
        showSnack(context, 'Photo updated.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: const ShellHeader(title: 'Edit profile', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          OutlinedButton.icon(
            onPressed: _saving ? null : _photo,
            icon: const Icon(Icons.photo_outlined),
            label: const Text('Change photo'),
          ),
          const SizedBox(height: 16),
          AuthField(label: 'Full name', controller: _name),
          const SizedBox(height: 16),
          AuthField(
            label: 'Phone',
            controller: _phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          AuthField(label: 'Address', controller: _address, maxLength: 1000),
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
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}
