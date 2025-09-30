class Schedule {
  final String id;
  final String tripId;
  final String title;
  final String? description;
  final String? location;
  final String category;
  final String priority;
  final DateTime startTime;
  final DateTime? endTime;

  Schedule({
    required this.id,
    required this.tripId,
    required this.title,
    this.description,
    this.location,
    required this.category,
    required this.priority,
    required this.startTime,
    this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['_id'],
      tripId: json['trip'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      category: json['category'],
      priority: json['priority'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }
}
