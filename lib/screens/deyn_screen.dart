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

          double totalBalance = snapshot.data!.docs.fold(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['amount'] ?? 0.0);
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Balance: \$${totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "\$${data['amount']}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data['description'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTransaction(context, doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, doc.id),
                            ),
                          ],
                        ),
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

  void _confirmDelete(BuildContext context, String transactionId) {
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this record?"),
            actions: [
              TextButton(
                onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: _isDeleting
                    ? null
                    : () async {
                  setState(() => _isDeleting = true);
                  await operations.deleteDiposit(transactionId);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: _isDeleting
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        });
      },
    );
  }

  void _addTransaction(BuildContext context) {
    TextEditingController amountController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: _isAdding
                      ? null
                      : () async {
                    final double? amount = double.tryParse(amountController.text);
                    if (amount != null) {
                      setState(() => _isAdding = true);
                      await operations.addDeposit(
                        personId,
                        amount,
                        descriptionController.text,
                        personName,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: _isAdding
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editTransaction(BuildContext context, String transactionId, Map<String, dynamic> data) {
    TextEditingController amountController =
    TextEditingController(text: data['amount'].toString());
    TextEditingController descriptionController =
    TextEditingController(text: data['description']);
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: _isUpdating
                      ? null
                      : () async {
                    final double? amount = double.tryParse(amountController.text);
                    if (amount != null) {
                      setState(() => _isUpdating = true);
                      await operations.updateDeposit(
                        transactionId,
                        amount,
                        descriptionController.text,
                        personName,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: _isUpdating
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
