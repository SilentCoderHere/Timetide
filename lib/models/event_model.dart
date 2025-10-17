class EventModel {
  int? id;
  String name;
  String? description;
  DateTime eventDate;
  String type;

  EventModel({
    this.id,
    required this.name,
    this.description,
    required this.eventDate,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      name: map['name'],
      description: map['description'],
      eventDate: DateTime.parse(map['eventDate']),
      type: map['type'],
    );
  }
}
