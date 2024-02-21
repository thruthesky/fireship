import 'package:fireship/fireship.functions.dart';

class CacheKey {
  final String group;
  final String id;

  CacheKey(
    this.group,
    this.id,
  );
}

class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  CacheService._() {
    dog('--> CacheService._()');
  }

  final Map<String, Map<String, dynamic>> _cache = {};

  dynamic get(CacheKey key) => _cache[key.group]?[key.id];

  void set(CacheKey key, dynamic value) {
    _cache[key.group] ??= {};
    _cache[key.group]![key.id] = value;
  }

  void remove(CacheKey key) {
    _cache[key.group]?.remove(key.id);
  }

  void clear() {
    _cache.clear();
  }

  void clearGroup(String group) {
    _cache.remove(group);
  }

  @override
  String toString() => "CacheService: ${_cache.toString()}";
}
