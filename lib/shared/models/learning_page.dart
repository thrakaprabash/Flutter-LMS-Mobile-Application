Map<String, dynamic> object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
String recordId(Map<String, dynamic> value) =>
    (value['id'] ?? value['_id'] ?? '').toString();
List<Map<String, dynamic>> records(dynamic value) =>
    value is List ? value.map(object).toList() : [];

class LearningPage {
  LearningPage(this.items, this.hasNext);
  final List<Map<String, dynamic>> items;
  final bool hasNext;
  factory LearningPage.decode(Map<String, dynamic> response, String key) {
    final data = response['data'];
    final map = object(data);
    final pagination = object(map['pagination'] ?? response['pagination']);
    return LearningPage(
      records(data is List ? data : map[key]),
      pagination['hasNextPage'] == true ||
          (pagination['page'] is num &&
              pagination['totalPages'] is num &&
              pagination['page'] < pagination['totalPages']),
    );
  }
}
