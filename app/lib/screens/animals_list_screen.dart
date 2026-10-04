import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/config.dart';
import '../api/media.dart';
import '../models/animal.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/media_photo.dart';
import '../widgets/status_chip.dart';
import 'animal_detail_screen.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
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
                emptyMessage: 'No animals are listed for adoption right now.',
                child: ListView.separated(
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
    final tokens = context.tokens;
    final photo = animal.photoUrls.isEmpty
        ? null
        : resolveMediaUrl(ApiConfig.current, animal.photoUrls.first);
    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnimalDetailScreen(animalId: animal.id),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius),
            child: photo == null
                ? Container(
                    width: 72,
                    height: 72,
                    color: tokens.muted,
                    child: Icon(Icons.pets_outlined, color: tokens.jungle),
                  )
                : MediaPhoto(url: photo, width: 72, height: 72),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: animal.statusLabel,
                  status: animal.adoptionStatus,
                ),
                const SizedBox(height: 6),
                Text(
                  animal.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    animal.species,
                    animal.breedType,
                    animal.sex,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
