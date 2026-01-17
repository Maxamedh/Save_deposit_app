import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:save_deposits/screens/summary_report_screen.dart';
import 'TransactionScreen.dart';
import 'package:save_deposits/operations.dart';
import 'package:save_deposits/screens/LoginScreen.dart';
import '../services/operations.dart';

class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  _DashboardscreenState createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Operations operations = Operations();

  late Operations1 _personOperations;
  late Stream<List<Person>> _personStream;
  String? _userEmail;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _personOperations = Operations1(_firestore);
    _personStream = _getPersonsForCurrentUser();
    _getUserDetails();

  }

  void _getUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userEmail = user.email ?? 'No email available';
          _userName = userDoc['name'] ?? 'No name available';
        });
      }
    }
  }

  Stream<List<Person>> _getPersonsForCurrentUser() {
    String userId = _auth.currentUser!.uid;
    return _firestore
        .collection('persons')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Person(
          id: doc.id,
          name: doc['name'],
          tell: doc['tell'],
        );
      }).toList();
    });
  }

  void _showAddDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController tellController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: tellController,
                decoration: const InputDecoration(labelText: 'Tell'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String userId = _auth.currentUser!.uid;
                await _firestore.collection('persons').add({
                  'name': nameController.text,
                  'tell': tellController.text,
                  'userId': userId,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password'),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                try {
                  User? user = _auth.currentUser;
                  if (user != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: oldPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPasswordController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _deletePerson(String personId) async {
    await _firestore.collection('persons').doc(personId).delete();
  }
  String formatBalance(double balance) {
    if (balance < 0) {
      return '-\$${balance.abs().toStringAsFixed(2)}';
    } else {
      return '\$${balance.toStringAsFixed(2)}';
    }
  }


  void _showDeleteDialog(String personId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this person?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePerson(personId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userName == null || _userEmail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5D9CEC), Color(0xFF4A89DC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: const Text('My Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? 'Loading...'),
              accountEmail: Text(_userEmail ?? 'Loading...'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, size: 50, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Summary Report'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SummaryReportScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _signOut(),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Person>>(
        stream: _personStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No persons found'));
          } else {
            var persons = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: persons.length,
              itemBuilder: (context, index) {
                var person = persons[index];
                return FutureBuilder<Map<String, double>>(
                  future: _fetchPersonTotals(person.id),
                  builder: (context, totalsSnapshot) {
                    if (totalsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (totalsSnapshot.hasError) {
                      return const Text('Error loading totals');
                    } else {
                      final totals = totalsSnapshot.data!;
                      final deposit = totals['deposit']!;
                      final withdraw = totals['withdraw']!;
                      final balance = deposit - withdraw;

                      return  GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionScreen(
                                  userName: person.name,
                                  userTell: person.tell,
                                  personId: person.id,
                                ),
                              ),
                            );
                            setState(() {}); // Refresh when back from TransactionScreen
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: Colors.deepPurple.withOpacity(0.3),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6A11CB), // deep purple
                                    Color(0xFF2575FC), // bright blue
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(0, 8),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          person.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                                color: Colors.black26,
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 22, color: Colors.white70),
                                            onPressed: () => _showEditDialog(context, person),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 22, color: Colors.redAccent),
                                            onPressed: () {
                                              _showDeleteDialog(person.id);
                                            },
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatBox('Credit(↑)', deposit, Colors.white.withOpacity(0.25), textColor: Colors.white),
                                      _buildStatBox('Debit(↓)', withdraw, Colors.white.withOpacity(0.25), textColor: Colors.white),
                                      _buildStatBox(
                                        'Balance',
                                        balance,
                                        Colors.white,
                                        textColor: balance < 0 ? Colors.red : Colors.deepPurple.shade700,
                                      ),


                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )

                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.blue.shade400,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatBox(String label, double value, Color color, {Color textColor = Colors.black}) {

    String displayValue = value < 0
        ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
          const SizedBox(height: 4),
          Text(" $displayValue",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Person person) {
    TextEditingController nameController = TextEditingController(text: person.name);
    TextEditingController tellController = TextEditingController(text: person.tell);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: tellController,
                decoration: const InputDecoration(labelText: 'Tell'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _personOperations.updatePerson(person.id, nameController.text, tellController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _fetchPersonTotals(String personId) async {
    final deposit = await operations.getTotalDeposits(personId);
    final withdraw = await operations.getTotalWithdraws(personId);
    return {'deposit': deposit, 'withdraw': withdraw};
  }
}

class Person {
  final String id;
  final String name;
  final String tell;

  Person({required this.id, required this.name, required this.tell});
}
