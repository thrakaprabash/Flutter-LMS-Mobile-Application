import 'package:flutter/foundation.dart';

import '../../../shared/providers/auth_provider.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this.service, this.feature, {this.courseId});
  final AdminService service;
  final String feature;
  final String? courseId;
  final Map<String, String> filters = {};
  List<Map<String, dynamic>> items = [];
  bool loading = false, saving = false, hasNext = false;
  String? error;
  int page = 0;
  int _generation = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  void emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool more = false, bool force = false}) async {
    if (_disposed || (more && (!hasNext || loading)) || (loading && !force)) {
      return;
    }
    final generation = ++_generation;
    final next = more ? page + 1 : 1;
    loading = true;
    error = null;
    emit();
    try {
      final result = await service.list(
        feature,
        next,
        Map.of(filters),
        courseId: courseId,
      );
      if (_disposed || generation != _generation) return;
      items = more ? [...items, ...result.items] : result.items;
      page = next;
      hasNext = result.hasNext;
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = AuthProvider.message(e);
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        emit();
      }
    }
  }

  Future<void> filter(String key, String value) async {
    if (value.isEmpty) {
      filters.remove(key);
    } else {
      filters[key] = value;
    }
    items = [];
    hasNext = false;
    await load(force: true);
  }

  Future<bool> mutate(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    if (saving || _disposed) return false;
    saving = true;
    error = null;
    emit();
    try {
      await service.request(method, path, data: data);
      if (_disposed) return false;
      await load(force: true);
      return true;
    } catch (e) {
      error = AuthProvider.message(e);
      return false;
    } finally {
      saving = false;
      emit();
    }
  }
}
