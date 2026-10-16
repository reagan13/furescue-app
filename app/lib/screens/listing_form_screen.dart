import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/confirm_action.dart';
import '../widgets/shell_header.dart';

class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _color = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  final _photos = <XFile>[];
  var _species = 'dog';
  var _sex = 'female';
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _color.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 8) {
      showSnack(context, 'Up to 8 photos can be attached.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) {
      return;
    }
    setState(() => _photos.add(file));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.isEmpty || description.isEmpty || _photos.isEmpty) {
      setState(
        () => _error = 'Name, profile, and at least one photo are required.',
      );
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Submit this listing?',
      message: 'This will send $name to City Vet for review.',
      confirmLabel: 'Submit for review',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final fields = <String, String>{
        'name': name,
        'species': _species,
        'sex': _sex,
        'breed_type': _species == 'cat' ? 'puspin' : 'aspin',
        'description': description,
      };
      final age = _age.text.trim();
      final color = _color.text.trim();
      if (age.isNotEmpty) {
        fields['age_estimate'] = age;
      }
      if (color.isNotEmpty) {
        fields['color_markings'] = color;
      }
      await SessionScope.of(context).api.postMultipart(
        '/api/v1/adoption-listings',
        fieldName: 'photos[]',
        filePaths: _photos.map((f) => f.path).toList(),
        fields: fields,
      );
      if (!mounted) {
        return;
      }
      showSnack(
        context,
        "Listing submitted. You'll be notified once it's reviewed.",
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: const ShellHeader(title: 'Post for adoption', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'Add the animal’s profile and at least one photo. City Vet reviews the listing before it goes live.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Name', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Ligaya',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Text('Species', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Dog (Aspin)'),
                selected: _species == 'dog',
                onSelected: _submitting
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() => _species = 'dog');
                        }
                      },
              ),
              ChoiceChip(
                label: const Text('Cat (Puspin)'),
                selected: _species == 'cat',
                onSelected: _submitting
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() => _species = 'cat');
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Sex', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Female'),
                selected: _sex == 'female',
                onSelected: _submitting
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() => _sex = 'female');
                        }
                      },
              ),
              ChoiceChip(
                label: const Text('Male'),
                selected: _sex == 'male',
                onSelected: _submitting
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() => _sex = 'male');
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Age estimate', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _age,
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'About 2 years',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Color / markings',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _color,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Brown with white chest',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Text('Profile', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _description,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Temperament, how it was rescued, and what home it needs.',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Photos (required)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _photos.length; i++)
                InputChip(
                  label: Text('Photo ${i + 1}'),
                  onDeleted: _submitting
                      ? null
                      : () => setState(() => _photos.removeAt(i)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Add photo'),
                onPressed: _submitting ? null : _addPhoto,
              ),
            ],
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
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting…' : 'Submit for review'),
          ),
        ],
      ),
    );
  }
}
