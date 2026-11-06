import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../format/display.dart';
import '../models/animal.dart';
import '../models/listing.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/async_body.dart';
import '../widgets/empty_prompt.dart';
import '../widgets/scan_card.dart';
import '../widgets/shell_header.dart';
import 'animal_detail_screen.dart';
import 'listing_form_screen.dart';

class ListingsListScreen extends StatefulWidget {
  const ListingsListScreen({super.key, this.focusId});

  final String? focusId;

  @override
  State<ListingsListScreen> createState() => _ListingsListScreenState();
}

class _ListingsListScreenState extends State<ListingsListScreen> {
  var _loading = true;
  String? _error;
  List<Listing> _items = const [];
  Map<String, Animal> _animals = const {};

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
      final api = SessionScope.of(context).api;
      final animalRows = await api.getList('/api/v1/animals?per_page=100');
      final listingRows = await api.getList(
        '/api/v1/adoption-listings?per_page=100',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _animals = {
          for (final animal in animalRows.map(Animal.fromJson))
            animal.id: animal,
        };
        _items = listingRows.map(Listing.fromJson).toList();
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

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ListingFormScreen()),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(title: 'My listings', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _create,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('New listing'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Rehome a rescued animal. Listings go live after a review by the City Veterinarian\'s Office.',
              style: Theme.of(context).textTheme.bodyMedium,
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
                emptyMessage: 'No listings yet.',
                emptyChild: EmptyPrompt(
                  icon: Icons.campaign_outlined,
                  title: 'No listings yet',
                  message: 'Rescued an animal that needs a new home? Post it here and we\'ll review it.',
                  actionLabel: 'Post for adoption',
                  onAction: _loading ? null : _create,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final card = _ListingCard(
                      item: item,
                      animal: _animals[item.animalId],
                    );
                    if (widget.focusId != item.id) return card;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.tokens.jungle, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: card,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item, required this.animal});

  final Listing item;
  final Animal? animal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final notes = item.reviewNotes?.trim();
    return ScanCard(
      photoPath: _photo(animal),
      title: _title(item, animal),
      subtitle: _meta(item, animal),
      statusLabel: item.statusLabel,
      status: item.status,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnimalDetailScreen(animalId: item.animalId),
          ),
        );
      },
      children: [
        if (item.status == 'approved')
          Text(
            'This listing is public — adopters can apply.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.jungle, fontWeight: FontWeight.w700),
          ),
        if (item.status == 'rejected' && notes != null && notes.isNotEmpty)
          Text(
            'Reviewer notes: $notes',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.destructive),
          ),
      ],
    );
  }
}

String _title(Listing item, Animal? animal) {
  final name = item.animalName?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (animal != null) return animal.displayName;
  return 'Listing';
}

String? _photo(Animal? animal) {
  if (animal == null || animal.photoUrls.isEmpty) {
    return null;
  }
  final first = animal.photoUrls.first.trim();
  return first.isEmpty ? null : first;
}

String? _meta(Listing item, Animal? animal) {
  final species = animal != null && animal.species.trim().isNotEmpty
      ? animal.species
      : (item.species ?? '');
  final when = timeAgo(item.createdAt);
  final parts = <String>[
    if (species.trim().isNotEmpty) labelWord(species),
    if (when.isNotEmpty) 'Posted $when',
  ];
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' · ');
}
