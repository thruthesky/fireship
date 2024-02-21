import 'package:fireship/fireship.dart';
import 'package:fireship/src/utility/cache.service.dart';
import 'package:flutter/material.dart';

class DisplayDatabasePhotos extends StatefulWidget {
  const DisplayDatabasePhotos({
    super.key,
    required this.path,
    this.cacheKey,
  });

  final String path;
  final CacheKey? cacheKey;

  @override
  State<DisplayDatabasePhotos> createState() => _DisplayDatabasePhotosState();
}

class _DisplayDatabasePhotosState extends State<DisplayDatabasePhotos> {
  @override
  Widget build(BuildContext context) {
    return Value(
      cacheKey: widget.cacheKey,
      path: widget.path,
      builder: (v) {
        return DisplayPhotos(urls: List<String>.from(v ?? []));
      },
    );
  }
}
