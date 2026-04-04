// poi_list.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/area.dart';
import '../models/poi.dart';

// Placeholder data - swap with API
final List<Poi> mockPois = [
  Poi(id: '1', areaId: 'central', name: 'Monas', description: 'National Monument of Indonesia', imageUrl: 'https://picsum.photos/seed/monas/400/200', address: 'Gambir, Central Jakarta'),
  Poi(id: '2', areaId: 'central', name: 'Istiqlal Mosque', description: 'Largest mosque in Southeast Asia', imageUrl: 'https://picsum.photos/seed/istiqlal/400/200', address: 'Sawah Besar, Central Jakarta'),
  Poi(id: '3', areaId: 'north', name: 'Kota Tua', description: 'Old Town of Jakarta', imageUrl: 'https://picsum.photos/seed/kotatua/400/200', address: 'Penjaringan, North Jakarta'),
];

class PoiList extends StatelessWidget {
  final String areaId;
  final bool isAdmin;

  const PoiList({
    required this.areaId,
    this.isAdmin = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final area = jakartaAreas.firstWhere((a) => a.id == areaId);
    final pois = mockPois.where((p) => p.areaId == areaId).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(area.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/admin/pois/$areaId/add'),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pois.length,
        itemBuilder: (context, index) {
          final poi = pois[index];
          return PoiCard(
            poi: poi,
            isAdmin: isAdmin,
            onTap: () => context.push(
              '/pois/$areaId/${poi.id}${isAdmin ? '?admin=true' : ''}',
            ),
            onEdit: isAdmin
                ? () => context.push(
                      '/admin/pois/$areaId/edit/${poi.id}',
                      extra: {'name': poi.name, 'description': poi.description},
                    )
                : null,
            onDelete: isAdmin ? () => _confirmDelete(context, poi) : null,
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Poi poi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete POI'),
        content: Text('Are you sure you want to delete "${poi.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: call delete API
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            Image.network(poi.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(poi.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (isAdmin) ...[
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
                      ],
                    ],
                  ),
                  Text(poi.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}