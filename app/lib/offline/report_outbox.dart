import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../screens/report_form_submit.dart';

class QueuedReport {
  const QueuedReport({
    required this.directory,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.filePaths,
  });

  final Directory directory;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> filePaths;
}

class FlushResult {
  const FlushResult({required this.sent, this.note});

  final int sent;
  final String? note;
}

/// Reports saved on the phone when the API cannot be reached.
class ReportOutbox {
  ReportOutbox(this.root);

  final Directory root;

  static Future<ReportOutbox> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}report-outbox');
    await dir.create(recursive: true);
    return ReportOutbox(dir);
  }

  Future<int> pendingCount() async {
    if (!await root.exists()) {
      return 0;
    }
    var count = 0;
    await for (final entity in root.list()) {
      if (entity is Directory && await File(_metaPath(entity)).exists()) {
        count++;
      }
    }
    return count;
  }

  Future<void> enqueue({
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> filePaths,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final folder = Directory('${root.path}${Platform.pathSeparator}$id');
    await folder.create(recursive: true);
    final stored = <String>[];
    for (var i = 0; i < filePaths.length; i++) {
      final source = File(filePaths[i]);
      final name = source.uri.pathSegments.isEmpty
          ? 'file-$i'
          : source.uri.pathSegments.last;
      final dest = File('${folder.path}${Platform.pathSeparator}$i-$name');
      await source.copy(dest.path);
      stored.add(dest.path);
    }
    await File(_metaPath(folder)).writeAsString(
      jsonEncode({
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'files': stored,
      }),
    );
  }

  Future<FlushResult> flush(ApiClient api) async {
    final queued = await _load();
    var sent = 0;
    String? note;
    for (final item in queued) {
      try {
        final result = await sendReport(
          api: api,
          description: item.description,
          address: item.address,
          latitude: item.latitude,
          longitude: item.longitude,
          photoPaths: item.filePaths,
        );
        await item.directory.delete(recursive: true);
        sent++;
        note = result.photoError;
      } on ApiException catch (e) {
        if (e.code == 'NETWORK') {
          return FlushResult(sent: sent, note: note);
        }
        await item.directory.delete(recursive: true);
        note = e.message;
      }
    }
    return FlushResult(sent: sent, note: note);
  }

  Future<List<QueuedReport>> _load() async {
    if (!await root.exists()) {
      return const [];
    }
    final items = <QueuedReport>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) {
        continue;
      }
      final meta = File(_metaPath(entity));
      if (!await meta.exists()) {
        continue;
      }
      final raw = jsonDecode(await meta.readAsString());
      if (raw is! Map) {
        continue;
      }
      final files = raw['files'];
      items.add(
        QueuedReport(
          directory: entity,
          description: (raw['description'] ?? '').toString(),
          address: (raw['address'] ?? '').toString(),
          latitude: (raw['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (raw['longitude'] as num?)?.toDouble() ?? 0,
          filePaths: files is List
              ? files.map((file) => file.toString()).toList()
              : const [],
        ),
      );
    }
    items.sort((a, b) => a.directory.path.compareTo(b.directory.path));
    return items;
  }

  String _metaPath(Directory folder) =>
      '${folder.path}${Platform.pathSeparator}report.json';
}

class ReportOutboxScope extends InheritedWidget {
  const ReportOutboxScope({
    super.key,
    required this.outbox,
    required super.child,
  });

  final ReportOutbox outbox;

  static ReportOutbox? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ReportOutboxScope>()
        ?.outbox;
  }

  @override
  bool updateShouldNotify(ReportOutboxScope oldWidget) =>
      outbox != oldWidget.outbox;
}
