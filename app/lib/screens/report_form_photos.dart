import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const reportMediaMaxBytes = 10 * 1024 * 1024;

const _allowedExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'mp4',
  'webm',
};

class ReportAttachment {
  const ReportAttachment({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;
}

Future<ReportAttachment?> chooseReportMedia(
  BuildContext context,
  ImagePicker picker,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery photo'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Record video'),
            onTap: () => Navigator.pop(context, 'record'),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Gallery video'),
            onTap: () => Navigator.pop(context, 'video'),
          ),
        ],
      ),
    ),
  );
  if (choice == null) {
    return null;
  }

  final XFile? file;
  switch (choice) {
    case 'camera':
      file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    case 'gallery':
      file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    case 'record':
      file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
    case 'video':
      file = await picker.pickVideo(source: ImageSource.gallery);
    default:
      return null;
  }
  if (file == null) {
    return null;
  }
  final isVideo = choice == 'record' || choice == 'video';
  return ReportAttachment(file: file, isVideo: isVideo);
}

String? reportMediaRejectReason(XFile file, int bytes) {
  if (bytes > reportMediaMaxBytes) {
    return 'That file is larger than 10 MB.';
  }
  final name = file.name;
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  if (_allowedExtensions.contains(ext)) {
    return null;
  }
  return 'Use a JPG, PNG, GIF, WEBP, MP4, or WEBM file.';
}
