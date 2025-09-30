class Trip {
  final String id;
  final String tripName;
  final String destination;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double? budget;
  final List<String> activities;
  final String coverImage; // <-- ADD THIS LINE

  Trip({
    required this.id,
    required this.tripName,
    required this.destination,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.budget,
    required this.activities,
    required this.coverImage, // <-- AND THIS LINE
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'],
      tripName: json['tripName'],
      destination: json['destination'],
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      budget: (json['budget'] as num?)?.toDouble(),
      activities: List<String>.from(json['activities'] ?? []),
      coverImage: json['coverImage'] ?? '', // <-- AND THIS LINE
    );
  }
}
