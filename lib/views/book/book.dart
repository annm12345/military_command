import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class BookView extends StatefulWidget {
  @override
  _BookViewState createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  String? localFilePath;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    downloadFile();
  }

  Future<void> downloadFile() async {
    try {
      final url = "https://militaryvoicecommand.000webhostapp.com/book/book.pdf";
      final filename = url.split('/').last;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      if (!(await file.exists())) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          setState(() {
            errorMessage = "Failed to download file: ${response.statusCode}";
            loading = false;
          });
          return;
        }
      }

      setState(() {
        localFilePath = file.path;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!),
                )
              : PDFView(
                  filePath: localFilePath!,
                ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BookView(),
  ));
}
