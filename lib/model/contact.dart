class Contact {
  final String? id;
  final String name;
  final String number;
  final String avatarUrl;

  Contact({
    this.id,
    required this.name,
    required this.number,
    required this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'avatarUrl': avatarUrl,
    };
  }

  static Contact fromMap(String id, Map<String, dynamic> map) {
    return Contact(
      id: id,
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }

  Contact copyWith({String? id, String? name, String? number, String? avatarUrl}) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
