import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // Required for PdfColor
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
        combinedData.add({
          'date': doc['timestamp'],
          'description': doc['description'],
          'amount': (doc['amount'] as num).toDouble(),
          'type': 'deposit',
        });
      }

      for (var doc in withdrawSnapshot.docs) {
        combinedData.add({
          'date': doc['timestamp'],
          'description': doc['description'],
          'amount': (doc['amount'] as num).toDouble(),
          'type': 'withdraw',
        });
      }

      // Sort by date ascending
      combinedData.sort((a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));

      // Recalculate balances after sorting
      double runningBalance = 0.0;
      List<Map<String, dynamic>> finalData = [];

      for (var data in combinedData) {
        double depositAmount = 0.0;
        double withdrawAmount = 0.0;

        if (data['type'] == 'deposit') {
          depositAmount = data['amount'];
          runningBalance += depositAmount;
        } else {
          withdrawAmount = data['amount'];
          runningBalance -= withdrawAmount;
        }

        finalData.add({
          'date': data['date'],
          'description': data['description'],
          'deposit': depositAmount,
          'withdraw': withdrawAmount,
          'balance': runningBalance,
        });
      }

      setState(() {
        reportData = finalData;
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

    final headerStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final dataStyle = pw.TextStyle(fontSize: 12);

    final blackColor = PdfColor.fromInt(0xFF000000);
    final blueGreyColor = PdfColor.fromInt(0xFF607D8B);

    // Calculate totals for PDF
    double totalDeposit = filteredData.fold(0.0, (sum, item) => sum + (item['deposit'] as double));
    double totalWithdraw = filteredData.fold(0.0, (sum, item) => sum + (item['withdraw'] as double));
    double balance = totalDeposit - totalWithdraw;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Person name header
            pw.Text(
              'Name : ${widget.personName}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headers: ['Date', 'Description', 'Deposit', 'Withdraw', 'Balance'],
              data: [
                ...filteredData.map((data) {
                  return [
                    _formatTimestamp(data['date']),
                    data['description'].toString(),
                    data['deposit'].toStringAsFixed(2),
                    data['withdraw'].toStringAsFixed(2),
                    data['balance'].toStringAsFixed(2),
                  ];
                }),
                [
                  'Total',
                  '',
                  totalDeposit.toStringAsFixed(2),
                  totalWithdraw.toStringAsFixed(2),
                  balance.toStringAsFixed(2),
                ],
              ],
              headerStyle: headerStyle,
              cellStyle: dataStyle,
              border: pw.TableBorder.all(width: 0.5, color: blackColor),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: blueGreyColor),
              cellHeight: 30,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report.pdf");
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    Share.shareXFiles([xFile], text: "Here is the report PDF");
  }


  @override
  Widget build(BuildContext context) {
    // Calculate totals for display
    double totalDeposit = filteredData.fold(0.0, (sum, item) => sum + (item['deposit'] as double));
    double totalWithdraw = filteredData.fold(0.0, (sum, item) => sum + (item['withdraw'] as double));
    double balance = totalDeposit - totalWithdraw;

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(' Name: ${ widget.personName} '
               ,  // or person.name
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Card(
                    elevation: 2,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Deposit')),
                        DataColumn(label: Text('Withdraw')),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: [
                        ...filteredData.map(
                          (data) => DataRow(cells: [
                            DataCell(Text(_formatTimestamp(data['date']))),
                            DataCell(Text(data['description'].toString())),
                            DataCell(Text(data['deposit'].toStringAsFixed(2))),
                            DataCell(Text(data['withdraw'].toStringAsFixed(2))),
                            DataCell(Text(data['balance'].toStringAsFixed(2))),
                          ]),
                        ),
                        DataRow(
                          color: MaterialStateProperty.all(Colors.blue.shade50),
                          cells: [
                            const DataCell(
                              Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const DataCell(Text('')),
                            DataCell(
                              Text(totalDeposit.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataCell(
                              Text(totalWithdraw.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataCell(
                              Text(balance.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
