import 'package:cloud_firestore/cloud_firestore.dart';

class Operations {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add Deyn transaction
  Future<void> addDeposit(String personId, double amount, String description,String personName) async {
    try {
      await _firestore.collection('deposit').add({
        'personId': personId,
        'amount': amount,
        'description': description,
        'personName': personName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding Deposit: $e');
    }
  }

  // Add DeynBixin transaction
  Future<void> addWithdraw(String personId, double amount, String description,String personName) async {
    try {
      await _firestore.collection('withdraw').add({
        'personId': personId,
        'amount': amount,
        'description': description,
        'personName': personName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding withdraw: $e');
    }
  }

  // Update Deyn transaction
  Future<void> updateDeposit(String transactionId, double amount, String description,String personName) async {
    try {
      await _firestore.collection('deposit').doc(transactionId).update({
        'amount': amount,
        'description': description,
        'personName': personName,
      });
    } catch (e) {
      print('Error updating Deposit: $e');
    }
  }

  // Update DeynBixin transaction
  Future<void> updatewithdraw(String transactionId, double amount, String description,String personName) async {
    try {
      await _firestore.collection('withdraw').doc(transactionId).update({
        'amount': amount,
        'description': description,
        'personName': personName,
      });
    } catch (e) {
      print('Error updating withdraw: $e');
    }
  }

  // Delete deposit transaction
  Future<void> deleteDiposit(String transactionId) async {
    try {
      await _firestore.collection('deposit').doc(transactionId).delete();
    } catch (e) {
      print('Error deleting Deposit: $e');
    }
  }

  // Delete withdraw transaction
  Future<void> deleteWithdraw(String transactionId) async {
    try {
      await _firestore.collection('withdraw').doc(transactionId).delete();
    } catch (e) {
      print('Error deleting withdraw: $e');
    }
  }

  // Fetch deposit transactions for a person
  Stream<QuerySnapshot> getDipositTransactions(String personId) {

    return _firestore.collection('deposit')
        .where('personId', isEqualTo: personId)// Ensure this orderBy matches the index
        .orderBy('timestamp', descending: true)
        .snapshots();

  }

  // Fetch withdraw transactions for a person
  Stream<QuerySnapshot> getWithdrawTransactions(String personId) {
    return _firestore.collection('withdraw')
        .where('personId', isEqualTo: personId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<double> getTotalDeposits(String personId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('deposit')
        .where('personId', isEqualTo: personId)
        .get();

    double total = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    return total;
  }

  Future<double> getTotalWithdraws(String personId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('withdraw')
        .where('personId', isEqualTo: personId)
        .get();

    double total = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
    return total;
  }
}
