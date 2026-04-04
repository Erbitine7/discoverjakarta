import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PoiAddEdit extends StatefulWidget {
  final String areaId;
  final String? poiId;
  final Map<String, dynamic>? poi; // null = add mode

  const PoiAddEdit({
    required this.areaId,
    this.poiId,
    this.poi,
    super.key,
  });

  @override
  State<PoiAddEdit> createState() => _PoiAddEditState();
}

class _PoiAddEditState extends State<PoiAddEdit> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _imageUrlController;

  bool get isEditing => widget.poi != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.poi?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.poi?['description'] ?? '');
    _addressController = TextEditingController(text: widget.poi?['address'] ?? '');
    _imageUrlController = TextEditingController(text: widget.poi?['imageUrl'] ?? '');
  }

  void _save() {
    // TODO: call add or edit API
    context.go('/pois/${widget.areaId}?admin=true');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit POI' : 'Add POI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: Text(isEditing ? 'Save Changes' : 'Add POI')),
            ),
          ],
        ),
      ),
    );
  }
}