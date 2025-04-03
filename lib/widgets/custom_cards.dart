import 'package:flutter/material.dart';
class LogoCard extends StatelessWidget {
  final String logoPath;
  final String systemName;

  const LogoCard({
    Key? key,
    required this.logoPath,
    required this.systemName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              logoPath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 12),
            Text(
              systemName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomersListCard extends StatelessWidget {
  final List<Map<String, String>> customers_list;

  const CustomersListCard({
    Key? key,
    required this.customers_list,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      margin: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit the height
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: customers_list.length,
                  itemBuilder: (context, index) {
                    final feature = customers_list[index];
                    return ListTile(
                      leading: const Icon(Icons.check, color: Colors.green),
                      title: Text(
                        feature['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        feature['subtitle'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        feature['endDate'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

