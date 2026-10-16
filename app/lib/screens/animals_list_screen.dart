import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../format/display.dart';
import '../models/animal.dart';
import '../session/session_scope.dart';
import '../widgets/async_body.dart';
import '../widgets/empty_prompt.dart';
import '../widgets/scan_card.dart';
import '../widgets/shell_header.dart';
import 'animal_detail_screen.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key, this.showAppBar = true});

  /// False when the resident shell already titles this tab Browse.
  /// A pushed route (for example from My adoptions) keeps the bar so it
  /// still has a title and a back button.
  final bool showAppBar;

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  var _loading = true;
  String? _error;
  String? _species;
  List<Animal> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = StringBuffer(
        '/api/v1/animals?adoption_status=available&per_page=50',
      );
      if (_species != null) {
        query.write('&species=$_species');
      }
      final rows = await SessionScope.of(context).api.getList(query.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows.map(Animal.fromJson).toList();
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

  void _setSpecies(String? value) {
    setState(() => _species = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _species != null;
    return Scaffold(
      appBar: widget.showAppBar
          ? const ShellHeader(title: 'Browse', showBack: true)
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.showAppBar ? 0 : 12, 16, 8),
            child: Text(
              'Meet the rescued animals currently looking for a forever home in Mati City.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _species == null,
                  onSelected: (_) => _setSpecies(null),
                ),
                ChoiceChip(
                  label: const Text('Dogs'),
                  selected: _species == 'dog',
                  onSelected: (_) => _setSpecies('dog'),
                ),
                ChoiceChip(
                  label: const Text('Cats'),
                  selected: _species == 'cat',
                  onSelected: (_) => _setSpecies('cat'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: AsyncBody(
                loading: _loading,
                error: _error,
                isEmpty: _items.isEmpty,
                onRetry: _load,
                emptyMessage: filtered
                    ? 'No animals match your filters.'
                    : 'No animals are listed for adoption right now.',
                emptyChild: EmptyPrompt(
                  icon: Icons.pets_outlined,
                  title: filtered
                      ? 'No animals match your filters'
                      : 'No animals listed yet',
                  message: filtered
                      ? 'Try clearing a filter — or check back soon, new rescues arrive regularly.'
                      : 'Check back soon. New rescues arrive regularly.',
                  actionLabel: filtered ? 'Show all' : null,
                  onAction: filtered ? () => _setSpecies(null) : null,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _AnimalCard(animal: _items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return ScanCard(
      photoPath: animal.photoUrls.isEmpty ? null : animal.photoUrls.first,
      fillFrame: true,
      aspectRatio: 4 / 3,
      title: animal.displayName,
      subtitle: _meta(animal),
      statusLabel: animal.statusLabel,
      status: animal.adoptionStatus,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnimalDetailScreen(animalId: animal.id),
          ),
        );
      },
    );
  }
}

String? _meta(Animal animal) {
  final age = animal.ageEstimate?.trim();
  final parts = <String>[
    if (animal.sex.trim().isNotEmpty) labelWord(animal.sex),
    if (animal.breedType.trim().isNotEmpty) labelWord(animal.breedType),
    if (age != null && age.isNotEmpty) age,
    if (animal.species.trim().isNotEmpty) labelWord(animal.species),
  ];
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' · ');
}
