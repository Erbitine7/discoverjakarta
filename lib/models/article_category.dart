class ArticleCategory {
  final String id;
  final String name;
  final String slug;

  const ArticleCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
