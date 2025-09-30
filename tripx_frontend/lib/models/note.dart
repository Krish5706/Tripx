class Note {
  final String id;
  final String tripId;
  final String title;
  final String? content;

  Note({
    required this.id,
    required this.tripId,
    required this.title,
    this.content,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'],
      tripId: json['trip'],
      title: json['title'],
      content: json['content'],
    );
  }
}
