import '../config/api_config.dart';

class Poi {
  final String id;
  final String areaId;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final String? categoryId;
  final String? categoryName;

  const Poi({
    required this.id,
    required this.areaId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    this.categoryId,
    this.categoryName,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'].toString(),
      areaId: json['location_slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: (json['image_url'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'] as String?,
    );
  }

  String get fullImageUrl {
    if (imageUrl.isEmpty) return imageUrl;
    final normalizedUrl = imageUrl.replaceAll('\\\\', '/');
    if (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://')) {
      return normalizedUrl;
    }
    final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1) : kApiBaseUrl;
    return '$base/image.php?path=${Uri.encodeComponent(normalizedUrl.startsWith('/') ? normalizedUrl.substring(1) : normalizedUrl)}';
  }
}
