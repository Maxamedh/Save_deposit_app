import 'package:flutter/material.dart';
import 'custom_cards.dart';

class Containerwidget extends StatelessWidget {
  const Containerwidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade800,
      ),
      foregroundDecoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First Card - Logo and System Name
          LogoCard(
            logoPath: 'images/wallet.png', // Replace with the path to your logo
            systemName: 'My System',
          ),

          // Second Card - Feature List with structured data
          CustomersListCard(
            customers_list: [
              {
                'name': 'Secure Login',
                'subtitle': 'Authenticate users with encryption.',
                'endDate': '2024-12-31',
              },
              {
                'name': 'Real-Time Data Sync',
                'subtitle': 'Keep data updated instantly.',
                'endDate': '2024-11-30',
              },
              {
                'name': 'User-Friendly Interface',
                'subtitle': 'Intuitive and modern design.',
                'endDate': '2024-10-15',
              },
              {
                'name': 'Offline Access',
                'subtitle': 'Access data without internet.',
                'endDate': '2024-09-30',
              },
              {
                'name': 'Multi-Platform Support',
                'subtitle': 'Use across various devices.',
                'endDate': '2024-08-31',
              },
            ],
          ),
        ],
      ),
    );
  }
}
