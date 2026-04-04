// poi_blog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/poi.dart';
import 'poi_list.dart'; // for mockPois

class PoiBlog extends StatelessWidget {
  final String areaId;
  final String poiId;
  final bool isAdmin;

  const PoiBlog({
    required this.areaId,
    required this.poiId,
    this.isAdmin = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final poi = mockPois.firstWhere((p) => p.id == poiId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(poi.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push(
                '/admin/pois/$areaId/edit/$poiId',
                extra: {'name': poi.name, 'description': poi.description},
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(poi.imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(poi.address, style: const TextStyle(color: Colors.grey)),
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
  }
}