import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../models/area.dart';
import '../models/article_category.dart';
import '../models/poi.dart';
import '../services/api_service.dart';

class PoiList extends StatefulWidget {
  final AuthNotifier auth;
  final String areaId;
  final bool isAdmin;

  const PoiList({
    required this.auth,
    required this.areaId,
    this.isAdmin = false,
    super.key,
  });

  @override
  State<PoiList> createState() => _PoiListState();
}

class _PoiListState extends State<PoiList> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ArticleCategory> _categories = [];
  List<Poi> _pois = [];
  String? _filterCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCategoriesAndPois();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndPois() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await apiService.fetchCategories();
      final list = await apiService.fetchPois(
        locationSlug: widget.areaId,
        categoryId: _filterCategoryId,
        searchQuery: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _categories = cats;
          _pois = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadCategoriesAndPois);
  }

  Future<void> _confirmDelete(Poi poi) async {
    final token = widget.auth.token;
    if (token == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete article'),
        content: Text('Delete "${poi.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await apiService.deletePoi(token: token, id: int.parse(poi.id));
      await _loadCategoriesAndPois();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = jakartaAreas.firstWhere((a) => a.id == widget.areaId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(area.name),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add article',
              onPressed: () => context.push('/admin/pois/${widget.areaId}/add'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _loadCategoriesAndPois(),
                  decoration: InputDecoration(
                    hintText: 'Search articles…',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadCategoriesAndPois();
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('filter_${_filterCategoryId}_${_categories.length}'),
                    initialValue: _filterCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _filterCategoryId = v);
                      _loadCategoriesAndPois();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(area.name)),
        ],
      ),
    );
  }

  Widget _buildBody(String areaName) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load articles.\nCheck that MySQL is running, you imported the SQL, and the Express API URL is correct.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadCategoriesAndPois, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_pois.isEmpty) {
      return Center(
        child: Text(
          'No articles match your search or filter in $areaName.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCategoriesAndPois,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _pois.length,
        itemBuilder: (context, index) {
          final poi = _pois[index];
          return PoiCard(
            poi: poi,
            isAdmin: widget.isAdmin,
            onTap: () => context.push('/pois/${widget.areaId}/${poi.id}'),
            onEdit: widget.isAdmin
                ? () => context.push('/admin/pois/${widget.areaId}/edit/${poi.id}')
                : null,
            onDelete: widget.isAdmin ? () => _confirmDelete(poi) : null,
          );
        },
      ),
    );
  }
}

class PoiCard extends StatelessWidget {
  final Poi poi;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PoiCard({
    required this.poi,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _coverImage(poi.fullImageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poi.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (poi.categoryName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                poi.categoryName!,
                                style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isAdmin) ...[
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(poi.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverImage(String url) {
    if (url.isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey)),
      );
    }
    return Image.network(
      url,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      ),
    );
  }
}
