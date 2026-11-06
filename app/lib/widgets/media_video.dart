import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/tokens.dart';

/// In-app player for a report mp4 or webm.
class MediaVideo extends StatefulWidget {
  const MediaVideo({super.key, required this.url, this.width, this.height});

  final String url;
  final double? width;
  final double? height;

  @override
  State<MediaVideo> createState() => _MediaVideoState();
}

class _MediaVideoState extends State<MediaVideo> {
  VideoPlayerController? _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = _controller;
    if (_failed || controller == null || !controller.value.isInitialized) {
      return Container(
        width: widget.width,
        height: widget.height ?? 160,
        color: tokens.muted,
        alignment: Alignment.center,
        child: Icon(
          _failed ? Icons.videocam_off_outlined : Icons.play_circle_outline,
          color: tokens.jungle,
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          IconButton(
            onPressed: () {
              setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              });
            },
            icon: Icon(
              controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: tokens.paper,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
