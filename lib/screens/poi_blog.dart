import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/poi.dart';
import '../services/api_service.dart';

class PoiBlog extends StatefulWidget {
  final String areaId;
  final String poiId;
  final bool isAdmin;

  const PoiBlog({
    required this.areaId,
    required this.poiId,
    this.isAdmin = false,
    super.key,
  });

  @override
  State<PoiBlog> createState() => _PoiBlogState();
}

class _PoiBlogState extends State<PoiBlog> {
  late Future<Poi> _future;

  @override
  void initState() {
    super.initState();
    _future = apiService.fetchPoi(int.parse(widget.poiId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Poi>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Article')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Could not load this article.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final poi = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: Text(poi.name),
            actions: [
              if (widget.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/admin/pois/${widget.areaId}/edit/${widget.poiId}'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(poi.fullImageUrl),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      if (poi.categoryName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          poi.categoryName!,
                          style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(poi.address, style: const TextStyle(color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(poi.description, style: const TextStyle(fontSize: 16, height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hero(String url) {
    if (url.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey)),
      );
    }
    return Image.network(
      url,
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 64)),
      ),
    );
  }
}
