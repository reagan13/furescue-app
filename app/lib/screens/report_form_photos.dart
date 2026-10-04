import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> chooseReportPhoto(
  BuildContext context,
  ImagePicker picker,
) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) {
    return null;
  }
  return picker.pickImage(source: source, imageQuality: 85);
}
