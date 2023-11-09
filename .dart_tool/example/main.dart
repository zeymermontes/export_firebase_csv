import 'package:export_firebase_csv/export_firebase_csv.dart';

void main() {
  // Ejemplo de uso de exportWithTitles
  exportDataFromFirebase();

  // Ejemplo de uso de jsonToCsv
  convertJsonToCsv();
}

void exportDataFromFirebase() async {
  String collectionName = 'employees';
  List<String> rowTitles = ['Name', 'Age', 'City'];
  List<String> fieldNames = ['name', 'age', 'city'];
  DateTime startDate = DateTime(2023, 1, 1);
  DateTime endDate = DateTime(2023, 1, 31);
  String dateFieldName = 'hireDate';

  await exportWithTitles(
    collectionName,
    rowTitles,
    fieldNames,
    startDate,
    endDate,
    dateFieldName,
  );
}

void convertJsonToCsv() {
  String jsonString = '[{"name": "Alice", "age": 30, "city": "New York"}, {"name": "Bob", "age": 25, "city": "Los Angeles"}]';
  String fileName = 'data';

  jsonToCsv(jsonString, fileName);
}
