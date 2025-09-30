class PackingListItem {
  final String id;
  final String tripId;
  final String itemName;
  final String category;
  bool isPacked;

  PackingListItem({
    required this.id,
    required this.tripId,
    required this.itemName,
    required this.category,
    required this.isPacked,
  });

  factory PackingListItem.fromJson(Map<String, dynamic> json) {
    return PackingListItem(
      id: json['_id'],
      tripId: json['trip'],
      itemName: json['itemName'],
      category: json['category'],
      isPacked: json['isPacked'] ?? false,
    );
  }
}
