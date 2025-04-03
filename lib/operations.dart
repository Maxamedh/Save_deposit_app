import 'package:cloud_firestore/cloud_firestore.dart';

class Operations {
  final FirebaseFirestore _firestore;

  Operations(this._firestore);

  // Function to update person info in Firestore
  Future<void> updatePerson(String personId, String name, String tell) async {
    try {
      await _firestore.collection('persons').doc(personId).update({
        'name': name,
        'tell': tell,
      });
    } catch (e) {
      print('Error updating person: $e');
    }
  }

  // Function to delete a person from Firestore
  Future<void> deletePerson(String personId) async {
    try {
      await _firestore.collection('persons').doc(personId).delete();
    } catch (e) {
      print('Error deleting person: $e');
    }
  }
}
