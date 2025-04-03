import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';  // Required for PdfColor
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class WarbixinScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const WarbixinScreen({Key? key, required this.personId, required this.personName}) : super(key: key);

  @override
  _WarbixinScreenState createState() => _WarbixinScreenState();
}

class _WarbixinScreenState extends State<WarbixinScreen> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> filteredData = [];
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchReportData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    try {
      final depositSnapshot = await FirebaseFirestore.instance
          .collection('deposit')
          .where('personId', isEqualTo: widget.personId)
          .get();

      final withdrawSnapshot = await FirebaseFirestore.instance
          .collection('withdraw')
          .where('personId', isEqualTo: widget.personId)
          .get();

      List<Map<String, dynamic>> combinedData = [];

      for (var doc in depositSnapshot.docs) {
        _currentBalance += doc['amount'];
        combinedData.add({
          'date': doc['timestamp'],
          'description': doc['description'],
          'amount': doc['amount'],
          'deposit': doc['amount'],
          'withdraw': 0.00,
          'balance': _currentBalance,
        });
      }

      for (var doc in withdrawSnapshot.docs) {
        _currentBalance -= doc['amount'];
        combinedData.add({
          'date': doc['timestamp'],
          'description': doc['description'],
          'amount': doc['amount'],
          'deposit': 0.00,
          'withdraw': doc['amount'],
          'balance': _currentBalance,
        });
      }

      setState(() {
        reportData = combinedData;
        filteredData = List.from(reportData);
      });
    } catch (e) {
      print('Error fetching report data: $e');
    }
  }

  void _filterData(String query) {
    setState(() {
      filteredData = reportData.where((data) {
        String dateStr = _formatTimestamp(data['date']);
        return dateStr.toLowerCase().contains(query.toLowerCase()) ||
            data['description'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _shareReport() async {
    final pdf = pw.Document();

    // Define custom text styles for headers and data
    final headerStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final dataStyle = pw.TextStyle(fontSize: 12);

    // Define colors using PdfColor (from the pdf package)
    final blackColor = PdfColor.fromInt(0x000000); // Black color
    final blueGreyColor = PdfColor.fromInt(0x607D8B); // Blue-grey color

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Amount', 'Deposit', 'Withdraw', 'Balance'],
                data: filteredData.map((data) {
                  return [
                    _formatTimestamp(data['date']),
                    data['description'].toString(),
                    data['deposit'].toString(),
                    data['withdraw'].toString(),
                    data['balance'].toString(),
                  ];
                }).toList(),
                headerStyle: headerStyle,
                cellStyle: dataStyle,
                border: pw.TableBorder.all(width: 0.5, color: blackColor),  // Using black color for the border
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(
                  color: blueGreyColor,  // Using blue-grey color for header
                ),
                cellHeight: 30,
                columnWidths: {
                  0: pw.FlexColumnWidth(2), // Date column width
                  1: pw.FlexColumnWidth(3), // Description column width
                  2: pw.FlexColumnWidth(2), // Deposit column width
                  3: pw.FlexColumnWidth(2), // Withdraw column width
                  4: pw.FlexColumnWidth(2), // Balance column width
                },
              ),
            ],
          );
        },
      ),
    );

    // Save the generated PDF file to a temporary directory
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report.pdf");
    await file.writeAsBytes(await pdf.save());

    final XFile xFile = XFile(file.path);
    Share.shareXFiles([xFile], text: "Here is the report PDF");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Report')),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _shareReport,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Report',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterData,
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Deposit')),
                    DataColumn(label: Text('Withdraw')),
                    DataColumn(label: Text('Balance')),
                  ],
                  rows: filteredData.map((data) => DataRow(cells: [
                    DataCell(Text(_formatTimestamp(data['date']))),
                    DataCell(Text(data['description'].toString())),
                    DataCell(Text(data['deposit'].toString())),
                    DataCell(Text(data['withdraw'].toString())),
                    DataCell(Text(data['balance'].toString())),
                  ])).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
