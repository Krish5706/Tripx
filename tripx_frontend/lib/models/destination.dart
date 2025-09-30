class Destination {
  final String id;
  final String name;
  final String country;
  final String description;
  final String imageUrl;
  final List<String> category;
  final List<String> bestSeason;
  final bool isDomestic;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.bestSeason,
    required this.isDomestic,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['_id'],
      name: json['name'],
      country: json['country'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      category: List<String>.from(json['category']),
      bestSeason: List<String>.from(json['bestSeason']),
      isDomestic: json['isDomestic'] ?? false,
    );
  }
}

