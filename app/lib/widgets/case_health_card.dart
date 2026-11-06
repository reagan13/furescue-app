import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/rescue_case.dart';
import 'section_card.dart';

class CaseHealthCard extends StatefulWidget {
  const CaseHealthCard({
    super.key,
    required this.health,
    this.onVaccination,
    this.onHeartRate,
  });

  final CaseHealth health;
  final Future<void> Function(String name, String date)? onVaccination;
  final Future<void> Function(int bpm)? onHeartRate;

  @override
  State<CaseHealthCard> createState() => _CaseHealthCardState();
}

class _CaseHealthCardState extends State<CaseHealthCard> {
  final _name = TextEditingController();
  final _date = TextEditingController();
  final _rate = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _saveVaccine() async {
    final name = _name.text.trim();
    final date = _date.text.trim();
    if (name.isEmpty || date.isEmpty || widget.onVaccination == null) return;
    setState(() => _busy = true);
    try {
      await widget.onVaccination!(name, date);
      _name.clear();
      _date.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveRate() async {
    final bpm = int.tryParse(_rate.text.trim());
    if (bpm == null || bpm < 1 || widget.onHeartRate == null) return;
    setState(() => _busy = true);
    try {
      await widget.onHeartRate!(bpm);
      _rate.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = widget.health;
    if (!health.hasAnimal) {
      return const SectionCard(
        icon: Icons.favorite_outline,
        title: 'Animal health',
        child: Text(
          'No animal record is linked to this case yet. City Vet adds the animal on the web console.',
        ),
      );
    }
    final rate = health.heartRate == null ? '—' : '${health.heartRate} bpm';
    return SectionCard(
      icon: Icons.favorite_outline,
      title: 'Animal health',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpecRow(label: 'Name', value: Text(health.animalName ?? 'Unnamed')),
          SpecRow(label: 'Species', value: Text(health.species ?? '—')),
          SpecRow(label: 'Notes', value: Text(health.notes ?? '—')),
          SpecRow(
            label: 'Vaccination',
            value: Text(health.vaccinationStatus ?? 'none'),
          ),
          SpecRow(label: 'Latest heart rate', value: Text(rate)),
          if (health.vaccinations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No vaccination recorded yet.'),
            )
          else
            for (final shot in health.vaccinations)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(shot),
              ),
          const SizedBox(height: 12),
          Text('Add a vaccination', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Vaccine name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _date,
            decoration: const InputDecoration(hintText: 'Date given (YYYY-MM-DD)'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _saveVaccine,
            child: const Text('Save vaccination'),
          ),
          const SizedBox(height: 16),
          Text('Add a heart-rate reading', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: _rate,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'Beats per minute'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _saveRate,
            child: const Text('Save heart rate'),
          ),
        ],
      ),
    );
  }
}
