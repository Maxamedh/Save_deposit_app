import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../services/operations.dart';

class SummaryReportScreen extends StatefulWidget {
  const SummaryReportScreen({Key? key}) : super(key: key);

  @override
  _SummaryReportScreenState createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Operations operations = Operations();

  late Stream<List<PersonSummary>> _summaryStream;
  String? _userName;
  String? _userEmail;

  final Color uiGradientTop = const Color(0xFF6A11CB);
  final Color uiGradientBottom = const Color(0xFF2575FC);

  @override
  void initState() {
    super.initState();
    _summaryStream = _getSummaryStreamForCurrentUser();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userEmail = user.email;
        _userName = doc.exists ? (doc.data()?['name'] ?? '') : '';
      });
    }
  }

  // Optimized async stream
  Stream<List<PersonSummary>> _getSummaryStreamForCurrentUser() {
    final String userId = _auth.currentUser!.uid;
    return _firestore
        .collection('persons')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        final id = doc.id;
        final name = doc['name'] ?? '';
        final tell = doc['tell'] ?? '';
        final results = await Future.wait([
          operations.getTotalDeposits(id),
          operations.getTotalWithdraws(id),
        ]);
        final deposit = results[0];
        final withdraw = results[1];
        return PersonSummary(
          id: id,
          name: name,
          tell: tell,
          credit: deposit,
          debit: withdraw,
          balance: deposit - withdraw,
        );
      }).toList();
      return await Future.wait(futures);
    });
  }

  String _formatCurrency(double value) =>
      value < 0 ? '-\$${value.abs().toStringAsFixed(2)}' : '\$${value.toStringAsFixed(2)}';

  Future<File> _createPdf(List<PersonSummary> rows) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final PdfColor pdfTop = PdfColor.fromInt(0xFF6A11CB);
    final PdfColor pdfBottom = PdfColor.fromInt(0xFF2575FC);

    double totalCredit = rows.fold(0.0, (p, e) => p + e.credit);
    double totalDebit = rows.fold(0.0, (p, e) => p + e.debit);
    final totalBalance = totalCredit - totalDebit;

    List<List<String>> tableData = rows
        .asMap()
        .entries
        .map((e) => [
      '${e.key + 1}',
      e.value.name,
      _formatCurrency(e.value.credit),
      _formatCurrency(e.value.debit),
      _formatCurrency(e.value.balance),
    ])
        .toList();

    tableData.add([
      'Total',
      '',
      _formatCurrency(totalCredit),
      _formatCurrency(totalDebit),
      _formatCurrency(totalBalance),
    ]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [pdfTop, pdfBottom]),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 18),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'All Accounts Summary Report',
              style: pw.TextStyle(
                  color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: ['#', 'Account Name', 'Credit', 'Debit', 'Balance']
                    .map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(e,
                      style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ))
                    .toList(),
              ),
              ...tableData.map((row) {
                final isTotal = row[0] == 'Total';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isTotal ? PdfColors.grey200 : PdfColors.white),
                  children: row.map((cell) {
                    final isNumber = cell.contains('\$') || cell.contains('-');
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        cell,
                        textAlign: isNumber ? pw.TextAlign.right : pw.TextAlign.left,
                        style: pw.TextStyle(
                            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/summary_report_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _exportAndSharePdf(List<PersonSummary> rows) async {
    try {
      final file = await _createPdf(rows);
      await Share.shareXFiles([XFile(file.path)], text: 'All Accounts Summary Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary Report', style: TextStyle(color: Colors.white)),
        backgroundColor: uiGradientTop,
      ),
      body: StreamBuilder<List<PersonSummary>>(
        stream: _summaryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          } else {
            final rows = snapshot.data!;
            final totalCredit = rows.fold(0.0, (p, e) => p + e.credit);
            final totalDebit = rows.fold(0.0, (p, e) => p + e.debit);
            final totalBalance = totalCredit - totalDebit;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportAndSharePdf(rows),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Summary as PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uiGradientTop,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      border: TableBorder.all(color: Colors.black, width: 1.0),
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(60),
                        1: FixedColumnWidth(250),
                        2: FixedColumnWidth(120),
                        3: FixedColumnWidth(120),
                        4: FixedColumnWidth(120),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade300),
                          children: const [
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('#',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Account Name',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Credit',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right)),
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Debit',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right)),
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Balance',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right)),
                          ],
                        ),
                        ...rows.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${i + 1}', textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(r.name,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                              Text(_formatCurrency(r.credit), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                              Text(_formatCurrency(r.debit), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_formatCurrency(r.balance),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color:
                                      r.balance < 0 ? Colors.red : Colors.green)),
                            ),
                          ]);
                        }).toList(),
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade200),
                          children: [
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Total',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_formatCurrency(totalCredit),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_formatCurrency(totalDebit),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_formatCurrency(totalBalance),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class PersonSummary {
  final String id;
  final String name;
  final String tell;
  final double credit;
  final double debit;
  final double balance;

  PersonSummary({
    required this.id,
    required this.name,
    required this.tell,
    required this.credit,
    required this.debit,
    required this.balance,
  });
}
