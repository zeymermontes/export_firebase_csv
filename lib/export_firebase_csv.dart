import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:download/download.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// Formats a Firestore [Timestamp] to a date and time string in the 'dd/MM/yyyy HH:mm:ss' format.
///
/// Converts a Firestore [Timestamp] object to a [DateTime] object and formats the date and time
/// in the desired format. This is useful for displaying Firestore dates in a human-readable format.
///
/// Parameters:
///   - [timestamp]: The Firestore [Timestamp] to be formatted.
///
/// Returns a date and time string in 'dd/MM/yyyy HH:mm:ss' format.
String formatFirestoreTimestamp(Timestamp timestamp) {
  // Converts the Timestamp to a DateTime object
  DateTime dateTime = timestamp.toDate();

  // Formats the date in the desired format
  String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

  return formattedDate;
}

/// Exports data from a Firebase collection to a CSV file and downloads it.
///
/// This function allows you to export data from a specific Firebase collection to a CSV file.
/// You can customize the exported data by providing the collection name, column titles, field names,
/// and date filters. The resulting CSV file is downloaded.
///
/// Parameters:
///   - [collectionName]: The name of the Firebase collection.
///   - [rowTitles]: List of titles for the CSV columns.
///   - [fieldNames]: List of field names to export.
///   - [start]: Start date for data filtering (Optional).
///   - [end]: End date for data filtering (Optional).
///   - [dateFieldName]: The name of the date field in the collection.
///   - [defaultNullString]: The default value in case of receiving a null value (Default value is an empty string).
///   - [fileName]: The name of the CSV file to be generated.
Future exportWithTitles(
  String collectionName,
  List<String> rowTitles,
  List<String> fieldNames,
  DateTime? start,
  DateTime? end,
  String dateFieldName,
  String? defaultNullString,
  String fileName,
) async {
  String dataString = '';
  if (start == null) {
    start = DateTime.now().subtract(Duration(
        hours: DateTime.now().hour,
        minutes: DateTime.now().minute,
        seconds: DateTime.now().second,
        milliseconds: DateTime.now().millisecond));
  }

  if (end == null) {
    end = start
        .add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
  }

  // Query for the documents
  final CollectionReference myCollection =
      FirebaseFirestore.instance.collection(collectionName);
  final QuerySnapshot querySnapshot = await myCollection
      .where(dateFieldName, isGreaterThanOrEqualTo: start)
      .where(dateFieldName, isLessThanOrEqualTo: end)
      .get();
  final List<QueryDocumentSnapshot> documents = querySnapshot.docs;
  print(documents.length);

  // Convert the data into CSV format
  List<dynamic> values = [];
  dataString = rowTitles.join(",") + "\n";

  for (final document in documents) {
    final data = document.data() as Map<String, dynamic>;
    for (var field in fieldNames) {
      if (data[field] is Timestamp) {
        values.add(formatFirestoreTimestamp(data[field]).toString());
      } else {
        if (data[field] != null) {
          values.add(data[field].toString());
        } else {
          values.add(defaultNullString ?? "");
        }
      }
    }

    dataString += values.join(",") + "\n";
    values = [];
  }

  // Generate a formatted timestamp for the filename
  final creationTime = DateFormat('dd_MM_yyyy_HH:mm:ss').format(DateTime.now());

  // Convert the CSV string to a list of bytes (Uint8List)
  Uint8List csvBytes = Uint8List.fromList(dataString.codeUnits);

  // Convert the Uint8List to a Stream<int>
  Stream<int> csvStream = Stream.fromIterable(csvBytes.map((byte) => byte));

  // Download the CSV file with a unique filename
  await download(csvStream, '$fileName-$creationTime.csv');
}

/// Converts JSON data to a CSV file and downloads it.
///
/// This function takes JSON data in the form of a JSON string or a Map/List of Maps and converts
/// it to a CSV file. The resulting CSV file is then downloaded. It also handles the replacement
/// of commas in values with semicolons to prevent CSV formatting issues.
///
/// Parameters:
///   - [jsonData]: JSON data to be converted to CSV (can be a JSON string, Map, or List of Maps).
///   - [fileName]: The name of the CSV file to be generated.
Future jsonToCsv(
  dynamic jsonData,
  String fileName,
) async {
  if (jsonData is String) {
    jsonData = jsonDecode(jsonData);
  } else if (jsonData is! Map<String, dynamic> &&
      jsonData is! List<Map<String, dynamic>>) {
    throw ArgumentError(
        'Invalid JSON data. It should be a JSON string, Map, or List of Maps.');
  }

  List<Map<String, dynamic>> jsonList;

  if (jsonData is Map<String, dynamic>) {
    // If jsonData is a single JSON object, wrap it in a list
    jsonList = [jsonData];
  } else {
    jsonList = jsonData as List<Map<String, dynamic>>;
  }

  if (jsonList.isEmpty) {
    throw ArgumentError('JSON data is empty.');
  }

  // Extract the headers from the first object
  List<String> headers = jsonList[0].keys.toList();

  // Create a string to hold the CSV data
  String dataString = headers.join(",") + "\n";

  for (Map<String, dynamic> json in jsonList) {
    List<String> values = [];
    for (String header in headers) {
      // Replace commas in values with semicolons to prevent CSV formatting issues
      values.add(json[header].toString().replaceAll(',', ';'));
    }
    dataString += values.join(",") + "\n";
  }

  // Generate a formatted timestamp for the filename
  final creationTime = DateFormat('dd_MM_yyyy_HH:mm:ss').format(DateTime.now());

  // Convert the CSV string to a list of bytes (Uint8List)
  Uint8List csvBytes = Uint8List.fromList(dataString.codeUnits);

  // Convert the Uint8List to a Stream<int>
  Stream<int> csvStream = Stream.fromIterable(csvBytes.map((byte) => byte));

  // Download the CSV file with a unique filename
  await download(csvStream, '$fileName-$creationTime.csv');
}
