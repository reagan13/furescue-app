import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/animal.dart';
import '../models/listing.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/status_chip.dart';
import 'animal_detail_screen.dart';
import 'listing_form_screen.dart';

class ListingsListScreen extends StatefulWidget {
  const ListingsListScreen({super.key});

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
      MaterialPageRoute<bool>(
        builder: (_) => const ListingFormScreen(),
      ),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _create,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('New listing'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage:
              'No listings yet. Post a rescued animal for adoption review.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = _items[i];
              final animal = _animals[item.animalId];
              return AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AnimalDetailScreen(animalId: item.animalId),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(label: item.statusLabel, status: item.status),
                    const SizedBox(height: 8),
                    Text(
                      animal?.displayName ?? 'Listing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.status == 'approved') ...[
                      const SizedBox(height: 6),
                      Text(
                        'This listing is public — adopters can apply.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (item.status == 'rejected' &&
                        item.reviewNotes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.reviewNotes!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.tokens.destructive),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
