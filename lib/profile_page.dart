import 'package:flutter/material.dart';
import 'custom_navigation_bar.dart';
import 'home_screen.dart';
import 'settings_page.dart';
import 'main.dart';
import 'config.dart';
import 'closed_tickets_page.dart';

class ProfilePage extends StatelessWidget {
  final String? name;
  final String? email;
  final int techId;

  const ProfilePage({
    Key? key,
    required this.name,
    required this.email,
    required this.techId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildProfileInfo('Name', name ?? 'N/A'),
            _buildProfileInfo('Email', email ?? 'N/A'),
            _buildProfileInfo('Tech ID', techId.toString()),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 2, // Updated to reflect ProfilePage index
        onTap: (index) {
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
              return; // Stay on ProfilePage
            case 3:
              newPage = SettingsPage(
                name: name,
                email: email,
                techId: techId,
              );
              break;
            default:
              newPage = Container();
          }

          Navigator.of(context).pushReplacement(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => newPage,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ));
        },
      ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '$title: $value',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
