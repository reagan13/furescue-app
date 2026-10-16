import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../widgets/shell_header.dart';

/// In-app playback for a `.glb` or `.gltf` the API already stored.
///
/// `model_viewer_plus` proxies the URL, so an `http://127.0.0.1:8000` model
/// still loads through `adb reverse`.
class ModelViewerScreen extends StatelessWidget {
  const ModelViewerScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ShellHeader(title: title, showBack: true),
      body: ModelViewer(
        src: url,
        alt: title,
        autoRotate: true,
        cameraControls: true,
        debugLogging: false,
      ),
    );
  }
}
