import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/auth_notifier.dart';
import '../../models/article_category.dart';
import '../../services/api_service.dart';

class PoiAddEdit extends StatefulWidget {
  final AuthNotifier auth;
  final String areaId;
  final String? poiId;

  const PoiAddEdit({
    required this.auth,
    required this.areaId,
    this.poiId,
    super.key,
  });

  @override
  State<PoiAddEdit> createState() => _PoiAddEditState();
}

class _PoiAddEditState extends State<PoiAddEdit> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  XFile? _imageFile;
  List<ArticleCategory> _categories = [];
  int? _categoryId;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get isEditing => widget.poiId != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final cats = await apiService.fetchCategories();
      if (isEditing) {
        final id = int.tryParse(widget.poiId!);
        if (id != null) {
          final poi = await apiService.fetchPoi(id);
          _nameController.text = poi.name;
          _descriptionController.text = poi.description;
          _addressController.text = poi.address;
          _categoryId = int.tryParse(poi.categoryId ?? '');
        }
      }
      if (mounted) {
        setState(() {
          _categories = cats;
          final ids = cats.map((c) => int.parse(c.id)).toSet();
          if (_categoryId == null || !ids.contains(_categoryId)) {
            _categoryId = cats.isNotEmpty ? int.parse(cats.first.id) : null;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _save() async {
    final token = widget.auth.token;
    if (token == null) return;

    final cat = _categoryId;
    if (cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a category')));
      return;
    }
    final title = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and description are required')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (isEditing) {
        final id = int.parse(widget.poiId!);
        await apiService.updatePoi(
          token: token,
          id: id,
          categoryId: cat,
          title: title,
          description: description,
          address: _addressController.text.trim(),
          imageFile: _imageFile,
        );
      } else {
        await apiService.createPoi(
          token: token,
          locationSlug: widget.areaId,
          categoryId: cat,
          title: title,
          description: description,
          address: _addressController.text.trim(),
          imageFile: _imageFile,
        );
      }
      if (mounted) context.go('/pois/${widget.areaId}');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit article' : 'Add article')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _bootstrap, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit article' : 'Add article')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey('poi_cat_${_categoryId}_${_categories.length}'),
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: int.parse(c.id),
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (_imageFile != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<Uint8List>(
                      future: _imageFile!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(snapshot.data!, fit: BoxFit.cover);
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error loading image: ${snapshot.error}'));
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No image selected')),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Save changes' : 'Publish article'),
            ),
          ],
        ),
      ),
    );
  }
}
