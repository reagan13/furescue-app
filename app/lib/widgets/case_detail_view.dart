import 'package:flutter/material.dart';

import '../format/display.dart';
import '../models/rescue_case.dart';
import '../theme/tokens.dart';
import 'activity_timeline.dart';
import 'brand_waves.dart';
import 'photo_strip.dart';
import 'section_card.dart';
import 'status_chip.dart';

class CaseDetailView extends StatelessWidget {
  const CaseDetailView({
    super.key,
    required this.item,
    required this.activity,
    required this.busy,
    this.onAccept,
    this.onDecline,
    this.onProof,
  });

  final RescueCase item;
  final List<CaseActivity> activity;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onProof;

  @override
  Widget build(BuildContext context) {
    final title = item.animalDescription?.isNotEmpty == true
        ? item.animalDescription!
        : 'Rescue case';
    final updated = timeAgo(item.updatedAt ?? item.createdAt);
    final created = timeAgo(item.createdAt);
    final notes = item.resolutionNotes?.trim();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BrandWaves(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: _HeroCopy(item: item, title: title, updated: updated),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.list(
            children: [
              SectionCard(
                icon: Icons.assignment_outlined,
                title: 'Case details',
                child: Column(
                  children: [
                    SpecRow(
                      label: 'Status',
                      value: StatusChip(
                        label: item.statusLabel,
                        status: item.status,
                      ),
                    ),
                    SpecRow(
                      label: 'ID',
                      value: _body(context, shortId(item.id)),
                    ),
                    if (created.isNotEmpty)
                      SpecRow(label: 'Opened', value: _body(context, created)),
                    if (updated.isNotEmpty)
                      SpecRow(label: 'Updated', value: _body(context, updated)),
                    if (notes != null && notes.isNotEmpty)
                      SpecRow(label: 'Notes', value: _body(context, notes)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                icon: Icons.pets_outlined,
                title: 'Source report',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SpecRow(label: 'Animal', value: _body(context, title)),
                    SpecRow(
                      label: 'Location',
                      value: _body(
                        context,
                        item.addressText?.isNotEmpty == true
                            ? item.addressText!
                            : '—',
                      ),
                    ),
                    if (item.reportPhotos.isNotEmpty)
                      PhotoStrip(urls: item.reportPhotos, height: 168)
                    else
                      Text(
                        'No report photos.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (item.canAddProof ||
                  item.resolutionPhotos.isNotEmpty ||
                  item.status == 'resolved') ...[
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Rescue proof',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.resolutionPhotos.isNotEmpty)
                        PhotoStrip(urls: item.resolutionPhotos, height: 168)
                      else
                        Text(
                          item.canAddProof
                              ? 'No proof uploaded yet.'
                              : 'No rescue proof uploaded.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (item.canAddProof) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Upload proof from the field. City Vet resolves the case on the web console.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (activity.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.timeline_outlined,
                  title: 'Activity',
                  child: ActivityTimeline(items: activity),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.bodyLarge);
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.item,
    required this.title,
    required this.updated,
  });

  final RescueCase item;
  final String title;
  final String updated;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = tokens.primaryForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusChip(
              label: item.statusLabel,
              status: item.status,
              onDark: true,
            ),
            const SizedBox(width: 8),
            Text(
              shortId(item.id),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: ink.withValues(alpha: 0.85)),
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ink),
        ),
        if (item.addressText != null && item.addressText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 16,
                color: ink.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.addressText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: ink.withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
        ],
        if (updated.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Updated $updated',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: ink.withValues(alpha: 0.75)),
          ),
        ],
      ],
    );
  }
}
