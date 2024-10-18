import 'package:flutter/material.dart';
import 'custom_navigation_bar.dart';
import 'profile_page.dart';
import 'home_screen.dart';
import 'main.dart';
import 'config.dart';
import 'closed_tickets_page.dart';

class SettingsPage extends StatelessWidget {
  final String? name;
  final String? email;
  final int techId;

  const SettingsPage({
    Key? key,
    required this.name,
    required this.email,
    required this.techId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromRGBO(234, 88, 12, 1),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Account'),
            onTap: () {
              // Navigate to account settings
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy and Security'),
            onTap: () {
              // Navigate to privacy and security settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help and Support'),
            onTap: () {
              // Navigate to help and support page
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              // Navigate to about page
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Implement logout functionality
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Widget newPage;
            switch (index) {
              case 0:
                newPage = HomeScreen(
                  techId: techId,
                  technicianData: {
                    'tech_name': name,
                    'tech_username': email,
                  },
                );
                break;
              case 1:
                newPage = ClosedTicketsPage(
                  techId: techId,
                  technicianData: {
                    'tech_name': name,
                    'tech_username': email,
                  },
                );
                break;
              case 2:
                newPage = ProfilePage(
                  name: name,
                  email: email,
                  techId: techId,
                );
                break;
              default:
                return;
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => newPage),
            );
          }
        },
      ),
    );
  }
}
