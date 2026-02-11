class SearchSuggestion {
  final String value;
  final String name;

  const SearchSuggestion({required this.value, required this.name});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      value: json['value'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'name': name};

  @override
  String toString() => 'SearchSuggestion(value: $value, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
