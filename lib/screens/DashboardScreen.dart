import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TransactionScreen.dart';
import 'package:save_deposits/operations.dart'; // Import the new class
import 'package:save_deposits/screens/LoginScreen.dart'; // Import the login screen

class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  _DashboardscreenState createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Operations _personOperations; // Instance of PersonOperations

  late Stream<List<Person>> _personStream;
  String? _userEmail;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _personOperations = Operations(_firestore);
    _personStream = _getPersonsForCurrentUser();
    _getUserDetails();
  }

  // Fetch user email and name from Firestore
  void _getUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userEmail = user.email ?? 'No email available';
          _userName = userDoc['name'] ?? 'No name available'; // Fetch name from Firestore
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
                String name = nameController.text;
                String tell = tellController.text;

                // Add new person to Firestore
                await _firestore.collection('persons').add({
                  'name': name,
                  'tell': tell,
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

  // Sign out the user and navigate to the login screen
  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to login screen
    );
  }

  // Dialog to change password
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
                String oldPassword = oldPasswordController.text;
                String newPassword = newPasswordController.text;
                String confirmPassword = confirmPasswordController.text;

                // Validate inputs
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')));
                  return;
                }

                try {
                  // Get current user
                  User? user = _auth.currentUser;
                  if (user != null) {
                    // Reauthenticate user before updating password
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: oldPassword,
                    );

                    await user.reauthenticateWithCredential(credential);

                    // Update password
                    await user.updatePassword(newPassword);

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed successfully')));
                    Navigator.of(context).pop(); // Close dialog
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userName == null || _userEmail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // Show loading until data is fetched
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
          title: const Text(
            'My Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? 'Loading...'),  // Safely handle null userName
              accountEmail: Text(_userEmail ?? 'Loading...'),  // Safely handle null userEmail
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, size: 50, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context); // Show password change dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _signOut(); // Call the sign out function
              },
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
            String userId = _auth.currentUser!.uid;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: persons.length,
              itemBuilder: (context, index) {
                var person = persons[index];
                return DashboardListTile(
                  title: person.name,
                  subtitle: person.tell,
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TransactionScreen(userId: userId, userName: person.name, userTell: person.tell, personId: person.id)),
                    );
                  },
                  onEdit: () {
                    _showEditDialog(context, person);
                  },
                  onDelete: () {
                    // Use PersonOperations class to delete the person
                    _personOperations.deletePerson(person.id);
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Use PersonOperations class to update the person
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
}

class Person {
  final String id;
  final String name;
  final String tell;

  Person({required this.id, required this.name, required this.tell});
}

class DashboardListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DashboardListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit,color: Colors.blue),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
