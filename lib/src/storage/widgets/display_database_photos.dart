import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';

class DisplayDatabasePhotos extends StatefulWidget {
  const DisplayDatabasePhotos({
    super.key,
    required this.path,
  });

  final String path;

  @override
  State<DisplayDatabasePhotos> createState() => _DisplayDatabasePhotosState();
}

class _DisplayDatabasePhotosState extends State<DisplayDatabasePhotos> {
  @override
  Widget build(BuildContext context) {
    return Value(
      path: widget.path,
      builder: (v) {
        return DisplayPhotos(urls: List<String>.from(v ?? []));
      },
    );
  }
}
