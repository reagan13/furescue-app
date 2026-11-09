import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/config.dart';
import '../api/json_map.dart';
import '../api/media.dart';
import '../models/animal.dart';
import '../session/session_scope.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';
import '../widgets/photo_strip.dart';
import '../widgets/shell_header.dart';
import '../widgets/status_chip.dart';
import 'model_viewer_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final _message = TextEditingController();
  Animal? _animal;
  var _loading = true;
  var _applying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SessionScope.of(context).api
          .get('/api/v1/animals/${widget.animalId}');
      if (!mounted) {
        return;
      }
      setState(() {
        _animal = Animal.fromJson(asJsonMap(data['animal']));
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _open3d(String raw, String title) async {
    final url = resolveMediaUrl(ApiConfig.current, raw);
    final path = url.toLowerCase().split('?').first;
    final playable = path.endsWith('.glb') || path.endsWith('.gltf');
    if (!playable) {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        showSnack(context, 'Could not open the 3D profile.');
      }
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModelViewerScreen(url: url, title: title),
      ),
    );
  }

  Future<void> _apply() async {
    final animal = _animal;
    if (animal == null) {
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Apply to adopt?',
      message: 'Submit an adoption application for ${animal.displayName}.',
      confirmLabel: 'Apply',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _applying = true);
    try {
      final body = <String, dynamic>{'animal_id': animal.id};
      final note = _message.text.trim();
      if (note.isNotEmpty) {
        body['message'] = note;
      }
      await SessionScope.of(context).api.post('/api/v1/adoptions', body: body);
      if (!mounted) {
        return;
      }
      showSnack(
        context,
        'Application submitted. Watch My Adoptions for updates.',
      );
      _message.clear();
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  Widget _profileButton(String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.view_in_ar_outlined),
      label: Text(label),
    );
  }

  Widget _modelSection(Animal animal) {
    final own = animal.model3dUrl?.trim();
    final staticUrl = animal.referenceModelUrl?.trim();
    final buttons = <Widget>[];
    if (own != null && own.isNotEmpty) {
      final mesh = own;
      buttons.add(
        _profileButton(
          'View this animal',
          () => _open3d(mesh, animal.displayName),
        ),
      );
    } else if (staticUrl != null && staticUrl.isNotEmpty) {
      final file = staticUrl;
      buttons.add(
        _profileButton(
          'View in 3D',
          () => _open3d(file, animal.displayName),
        ),
      );
    }
    if (buttons.isEmpty) {
      return Text(
        'No 3D profile uploaded yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          buttons[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = _animal;
    return Scaffold(
      appBar: ShellHeader(
        title: animal?.displayName ?? 'Animal',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: animal == null,
          onRetry: _load,
          emptyMessage: 'Animal not found.',
          // The child is built before AsyncBody can hide it. animal! on this
          // list threw on the first frame, before the GET returned.
          child: animal == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
                  children: [
                    if (animal.photoUrls.isNotEmpty) ...[
                      PhotoStrip(urls: animal.photoUrls, height: 220),
                      const SizedBox(height: 20),
                    ],
                    StatusChip(
                      label: animal.statusLabel,
                      status: animal.adoptionStatus,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      [
                        animal.species,
                        animal.breedType,
                        animal.sex,
                        if (animal.ageEstimate != null) animal.ageEstimate!,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (animal.colorMarkings != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        animal.colorMarkings!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (animal.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        animal.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (animal.photo360Set.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '360 set',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      PhotoStrip(urls: animal.photo360Set),
                    ],
                    const SizedBox(height: 16),
                    _modelSection(animal),
                    if (animal.isAvailable) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Apply to adopt',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _message,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText: 'Optional note for City Vet',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _applying ? null : _apply,
                        child: Text(
                          _applying ? 'Submitting…' : 'Submit application',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
