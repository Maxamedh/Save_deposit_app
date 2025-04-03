import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/operations.dart';

class DepositScreen extends StatelessWidget {
  final String personId;
  final String personName;
  final Operations operations = Operations();

  DepositScreen({required this.personId,required this.personName});

  @override
  Widget build(BuildContext context) {
    var data = operations.getDipositTransactions(personId);
    print(data);
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Transactions')),
      body: StreamBuilder(
        stream: operations.getDipositTransactions(personId),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Deposit transactions found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text("Amount: \$${data['amount']} "),
                subtitle: Text(data['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editTransaction(context, doc.id, data),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => operations.deleteDiposit(doc.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTransaction(context),
        child: Icon(Icons.add),
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
          title: Text('Add Deposit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await operations.addDeposit(personId, double.parse(amountController.text), descriptionController.text,personName);
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editTransaction(BuildContext context, String transactionId, Map<String, dynamic> data) {
    TextEditingController amountController = TextEditingController(text: data['amount'].toString());
    TextEditingController descriptionController = TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Deposit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await operations.updateDeposit(transactionId, double.parse(amountController.text), descriptionController.text,personName);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
