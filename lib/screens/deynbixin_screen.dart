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
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: _isAdding ? null : () async {
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
                        setState(() => _isAdding = true);
                        await operations.addWithdraw(
                          widget.personId,
                          withdrawAmount,
                          descriptionController.text,
                          widget.personName,
                        );
                        await _calculateBalance();
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid amount entered')),
                      );
                    } finally {
                      if (mounted) setState(() => _isAdding = false);
                    }
                  },
                  child: _isAdding
                      ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                      : Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _editWithdrawTransaction(BuildContext context, String transactionId, Map<String, dynamic> data) {
    TextEditingController amountController = TextEditingController(text: data['amount'].toString());
    TextEditingController descriptionController = TextEditingController(text: data['description']);
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: _isUpdating ? null : () async {
                    try {
                      double updatedAmount = double.parse(amountController.text);
                      if (updatedAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      setState(() => _isUpdating = true);
                      await operations.updatewithdraw(
                        transactionId,
                        updatedAmount,
                        descriptionController.text,
                        widget.personName,
                      );
                      Navigator.pop(context);
                      await _calculateBalance();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid amount entered')),
                      );
                    } finally {
                      if (mounted) setState(() => _isUpdating = false);
                    }
                  },
                  child: _isUpdating
                      ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                      : Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _confirmDelete(BuildContext context, String transactionId) {
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Confirm Delete"),
              content: Text("Are you sure you want to delete this transaction?"),
              actions: [
                TextButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: _isDeleting ? null : () async {
                    setState(() => _isDeleting = true);
                    await operations.deleteWithdraw(transactionId);
                    await _calculateBalance();
                    if (mounted) Navigator.pop(context);
                  },
                  child: _isDeleting
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                      : Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
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
                  return Center(child: Text('No withdraw transactions found.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "\$${data['amount']}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editWithdrawTransaction(context, doc.id, data),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, doc.id),
                            ),
                          ],
                        ),
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
