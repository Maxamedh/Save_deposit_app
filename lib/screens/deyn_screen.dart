import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/operations.dart';

class DepositScreen extends StatelessWidget {
  final String personId;
  final String personName;
  final Operations operations = Operations();

  DepositScreen({required this.personId, required this.personName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Transactions')),
      body: StreamBuilder(
        stream: operations.getDipositTransactions(personId),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No deposit transactions found.'));
          }

          // Calculate total balance
          double totalBalance = snapshot.data!.docs.fold(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['amount'] ?? 0.0);
          });

          return Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Text(
              //     'Total Balance: \$${totalBalance.toStringAsFixed(2)}',
              //     style: const TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.green,
              //     ),
              //   ),
              // ),
              Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text("Amount: \$${data['amount']}"),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTransaction(context, doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => operations.deleteDiposit(doc.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTransaction(BuildContext context) {
    TextEditingController amountController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Deposit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final double? amount = double.tryParse(amountController.text);
                if (amount != null) {
                  await operations.addDeposit(
                    personId,
                    amount,
                    descriptionController.text,
                    personName,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editTransaction(BuildContext context, String transactionId, Map<String, dynamic> data) {
    TextEditingController amountController =
    TextEditingController(text: data['amount'].toString());
    TextEditingController descriptionController =
    TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Deposit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final double? amount = double.tryParse(amountController.text);
                if (amount != null) {
                  await operations.updateDeposit(
                    transactionId,
                    amount,
                    descriptionController.text,
                    personName,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
