import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_deposits/screens/WarbixinScreen.dart';
import 'package:save_deposits/screens/deyn_screen.dart';
import 'package:save_deposits/screens/deynbixin_screen.dart';
import '../services/operations.dart';

class TransactionScreen extends StatefulWidget {
  final String userName;
  final String userTell;
  final String userId;
  final String personId;

  const TransactionScreen({
    Key? key,
    required this.userName,
    required this.userTell,
    required this.userId,
    required this.personId,
  }) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

final Operations operations = Operations();
double availableBalance = 0.0;

class _TransactionScreenState extends State<TransactionScreen> {
  late TextEditingController _amountController;
  double totalDeposits = 0.0;
  double totalWithdraws = 0.0;
  List<Map<String, dynamic>> reportData = [];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _fetchTransactionData();
    _calculateBalance();
  }

  Future<void> _calculateBalance() async {
    double deposits = await operations.getTotalDeposits(widget.personId);
    double withdraws = await operations.getTotalWithdraws(widget.personId);
    print('deposit: $deposits');
    print('withdraws: $withdraws');
    setState(() {
      totalDeposits = deposits;
      totalWithdraws = withdraws;
      availableBalance =
          (totalDeposits - totalWithdraws).clamp(0.0, double.infinity);
    });
  }

  Future<void> _fetchTransactionData() async {
    try {
      final reportSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        reportData = reportSnapshot.docs
            .map((doc) => {
          'id': doc.id,
          'amount': doc['amount'],
          'date': doc['date']
        })
            .toList();
      });
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance:',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '\$${availableBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallCard('Deposit', totalDeposits, Colors.green,
                    Icons.check, () => _navigateToDeyntaScreen(context)),
                _buildSmallCard('Withdraw', totalWithdraws, Colors.red,
                    Icons.warning, () => _navigateToDeynBixintaScreen(context)),
                _buildSmallCardReport('Report', Colors.orange,
                    Icons.insert_chart, () => _navigateToWarbixinScreen(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, num count, Color color, IconData icon,
      Function onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(),
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  count.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCardReport(
      String title, Color color, IconData icon, Function onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(),
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDeyntaScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(
          personId: widget.personId,
          personName: widget.userName,
        ),
      ),
    );
    _calculateBalance(); // Refresh balance
    _fetchTransactionData(); // Refresh transactions
  }

  void _navigateToDeynBixintaScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(
          personId: widget.personId,
          personName: widget.userName,
        ),
      ),
    );
    _calculateBalance(); // Refresh balance
    _fetchTransactionData(); // Refresh transactions
  }

  void _navigateToWarbixinScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarbixinScreen(
          personId: widget.personId,
          personName: widget.userName,
        ),
      ),
    );
  }
}
