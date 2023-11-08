import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

String formatFirestoreTimestamp(Timestamp timestamp) {
  // Convierte el Timestamp en un objeto DateTime
  DateTime dateTime = timestamp.toDate();

  // Formatea la fecha en el formato deseado
  String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

  return formattedDate;
}

Future exportWithTitles(
  String collectionName,
  List<String> rowTitles,
  List<String> fieldNames,
  DateTime? start,
  DateTime? end,
  String dateFieldName,
  String? defaultNullString,
) async {
  // Add your function code here!

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
  //final QuerySnapshot querySnapshot = await myCollection.get();
  final QuerySnapshot querySnapshot = await myCollection
      .where(dateFieldName, isGreaterThanOrEqualTo: start)
      .where(dateFieldName, isLessThanOrEqualTo: end)
      .get();
  final List<QueryDocumentSnapshot> documents = querySnapshot.docs;

// Convert the data into CSV format
  final List<List<dynamic>> rows = [];
  List<dynamic> values = [];
  rows.add(rowTitles); // Add header row
  for (final document in documents) {
    //final id = document.id;
    final data = document.data() as Map<String, dynamic>;
    for (var field in fieldNames) {
      if (data[field] is Timestamp) {
        print("Entra");

        values.add(formatFirestoreTimestamp(data[field]));
      } else {
        print("no Entra");
        if (data[field] != null) {
          values.add(data[field]);
        } else {
          values.add(defaultNullString ?? "");
        }
      }
    }

    rows.add(values);
    values = [];
  }
  final csvData = const ListToCsvConverter().convert(rows);

// Download the CSV file
  final bytes = utf8.encode(csvData);
  final base64Data = base64Encode(bytes);
  final uri = 'data:text/csv;base64,$base64Data';
  await launchUrl(Uri.parse(uri));
}