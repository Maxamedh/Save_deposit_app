import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/operations.dart';

class WithdrawScreen extends StatefulWidget {
  final String personId;
  final String personName;

  WithdrawScreen({required this.personId, required this.personName});

  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final Operations operations = Operations();
  double availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateBalance();
  }

  Future<void> _calculateBalance() async {
    double totalDeposits = await operations.getTotalDeposits(widget.personId);
    double totalWithdraws = await operations.getTotalWithdraws(widget.personId);

    setState(() {
      availableBalance = (totalDeposits - totalWithdraws).clamp(0.0, double.infinity);
    });
  }

  void _addWithdrawTransaction(BuildContext context) {
    TextEditingController amountController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Withdraw'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  double withdrawAmount = double.parse(amountController.text);
                  if (withdrawAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount')),
                    );
                  } else if (withdrawAmount > availableBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Insufficient balance')),
                    );
                  } else {
                    await operations.addWithdraw(
                        widget.personId, withdrawAmount, descriptionController.text, widget.personName);
                    _calculateBalance();
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid amount entered')),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editWithdrawTransaction(BuildContext context, String transactionId, Map<String, dynamic> data) {
    TextEditingController amountController = TextEditingController(text: data['amount'].toString());
    TextEditingController descriptionController = TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Withdraw'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  double updatedAmount = double.parse(amountController.text);
                  if (updatedAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount')),
                    );
                  } else {
                    await operations.updatewithdraw(
                        transactionId, updatedAmount, descriptionController.text, widget.personName);
                    Navigator.pop(context);
                    _calculateBalance();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid amount entered')),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Withdraw Transactions')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Available Balance: \$${availableBalance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: operations.getWithdrawTransactions(widget.personId),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No Withdraw transactions found.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text("Amount: \$${data['amount']}"),
                      subtitle: Text(data['description']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Fixes overflow issue
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editWithdrawTransaction(context, doc.id, data),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await operations.deleteWithdraw(doc.id);
                              _calculateBalance();
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWithdrawTransaction(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
