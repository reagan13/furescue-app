import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/confirm_action.dart';
import '../offline/report_outbox.dart';
import '../widgets/pin_map.dart';
import 'report_form_locate.dart';
import 'report_form_photos.dart';
import 'report_form_submit.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _picker = ImagePicker();
  final _media = <ReportAttachment>[];
  double? _lat;
  double? _lng;
  var _locating = false;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final pin = await readCurrentReportPin();
      if (!mounted) {
        return;
      }
      setState(() {
        _lat = pin.latitude;
        _lng = pin.longitude;
        _locating = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _locating = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not read GPS. Try again outdoors.';
        _locating = false;
      });
    }
  }

  Future<void> _addMedia() async {
    if (_media.length >= 8) {
      showSnack(context, 'Up to 8 photos or videos can be attached.');
      return;
    }
    final picked = await chooseReportMedia(context, _picker);
    if (picked == null || !mounted) {
      return;
    }
    final bytes = await picked.file.length();
    if (!mounted) {
      return;
    }
    final reason = reportMediaRejectReason(picked.file, bytes);
    if (reason != null) {
      showSnack(context, reason);
      return;
    }
    setState(() => _media.add(picked));
  }

  Future<void> _submit() async {
    final description = _description.text.trim();
    if (description.isEmpty) {
      setState(() => _error = 'Describe the animal.');
      return;
    }
    if (_media.isEmpty) {
      setState(() => _error = 'Attach at least one photo or video.');
      return;
    }
    if (_lat == null || _lng == null) {
      setState(() => _error = 'Use GPS so the pin is inside Mati City.');
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Create this report?',
      message: 'This will submit a new stray-animal report.',
      confirmLabel: 'Create report',
    );
    if (!ok || !mounted) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final sent = await sendReport(
        api: SessionScope.of(context).api,
        description: description,
        address: _address.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        photoPaths: _media.map((item) => item.file.path).toList(),
      );
      if (!mounted) {
        return;
      }
      if (sent.photoError != null) {
        showSnack(context, sent.photoError!);
      }
      final flash = sent.report.isFlaggedDuplicate
          ? 'A similar report exists nearby — yours was flagged for review.'
          : 'Report submitted. Our team will verify it shortly.';
      showSnack(context, flash);
      _description.clear();
      _address.clear();
      setState(() {
        _media.clear();
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'NETWORK') {
        final outbox = ReportOutboxScope.maybeOf(context);
        if (outbox != null) {
          await outbox.enqueue(
            description: description,
            address: _address.text.trim(),
            latitude: _lat!,
            longitude: _lng!,
            filePaths: _media.map((item) => item.file.path).toList(),
          );
          if (!mounted) {
            return;
          }
          _description.clear();
          _address.clear();
          setState(() {
            _media.clear();
            _lat = null;
            _lng = null;
            _submitting = false;
            _error = null;
          });
          showSnack(
            context,
            'Saved on this phone. It will send when the connection returns.',
          );
          return;
        }
      }
      setState(() {
        _error = e.code == 'OUT_OF_BOUNDS'
            ? 'Location is outside Mati City.'
            : e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final pin = _lat != null && _lng != null
        ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
        : 'No pin yet';
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Pin the animal in Mati City. Bounds are checked on the server.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'What did you see?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _description,
            maxLines: 5,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Species, color, condition, and what is happening.',
            ),
          ),
          const SizedBox(height: 12),
          Text('Location', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(pin, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _locating || _submitting ? null : _locate,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_lat == null ? 'Use my GPS' : 'Refresh GPS'),
          ),
          const SizedBox(height: 12),
          PinMap(latitude: _lat, longitude: _lng),
          const SizedBox(height: 16),
          Text(
            'Address (optional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _address,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Barangay or landmark',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Photos or video (required, up to 8)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _media.length; i++)
                InputChip(
                  label: Text(
                    _media[i].isVideo ? 'Video ${i + 1}' : 'Photo ${i + 1}',
                  ),
                  onDeleted: _submitting
                      ? null
                      : () => setState(() => _media.removeAt(i)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Add photo or video'),
                onPressed: _submitting ? null : _addMedia,
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
            child: _submitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.primaryForeground,
                    ),
                  )
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
