import 'package:flutter/material.dart';  // Import the Flutter material package
import 'home_screen.dart'; // Add this import
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for JSON encoding/decoding
import 'dart:io';  // Add this import for SocketException
import 'dart:async';  // Add this import for TimeoutException
import 'config.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HELPDEX Technician Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: const TextStyle(fontFamily: 'Nunito', color: Colors.black87), // Updated from bodyText1
          headlineSmall: const TextStyle(fontFamily: 'Nunito', color: Color.fromRGBO(234, 88, 12, 1)), // Updated from headline6
        ),
      ),
      home: const LoginPage(),  // Changed from LoginScreen to LoginPage
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _connectionStatus = 'Checking connection...';

  final Color _customOrange = const Color.fromRGBO(234, 88, 12, 1);

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkConnection() async {
    setState(() {
      _connectionStatus = 'Checking connection...';
    });

    try {
      print('Attempting to connect to server...');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/mobile/testConnection.php')
      ).timeout(const Duration(seconds: 10));

      print('Response received. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _connectionStatus = jsonResponse['message'];
        });
      } else {
        setState(() {
          _connectionStatus = 'Failed to connect to the server. Status code: ${response.statusCode}';
        });
      }
    } on SocketException catch (e) {
      print('SocketException caught: ${e.toString()}');
      setState(() {
        _connectionStatus = 'Connection refused. Is the server running?';
      });
    } on TimeoutException catch (e) {
      print('TimeoutException caught: ${e.toString()}');
      setState(() {
        _connectionStatus = 'Connection timed out. Check your network or server status.';
      });
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      setState(() {
        _connectionStatus = 'Error: ${e.toString()}';
      });
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> body = {
        'username': _usernameController.text,
        'password': _passwordController.text,
      };

      try {
        print('Attempting to log in with username: ${body['username']}');
        print('Login body: $body');

        final response = await http.post(
          Uri.parse('${Config.baseUrl}/mobile/loginOnMobile.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        print('Login response status code: ${response.statusCode}');
        print('Login response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == 'success') {
            final techId = jsonResponse['user']['tech_id'] as int;
            final technician = jsonResponse['user']; // Store technician data

            // Fetch technician data
            final technicianResponse = await http.get(
              Uri.parse('${Config.baseUrl}technicianDetails.php?tech_id=$techId'),
              headers: {'Content-Type': 'application/json'},
            );

            print('Technician response status code: ${technicianResponse.statusCode}'); // Debugging statement
            if (technicianResponse.statusCode == 200) {
              final technicianData = json.decode(technicianResponse.body);
              print('Parsed technician data: $technicianData');

              if (technicianData['success']) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      techId: techId,
                      technicianData: technician, // Pass the technician data
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to fetch technician data: ${technicianData['message']}')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to fetch technician data. Please try again.')),
              );
            }
          } else if (jsonResponse['status'] == 'error') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonResponse['message'])),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unexpected response from server. Please try again.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid username or password.')),
          );
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/img/dswd/dswd-fo-logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'HELPDEX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _customOrange,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'IT Support System',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Image.asset(
                  'assets/img/bear/dswd bear-removebg.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: Icon(Icons.person, color: _customOrange),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: Icon(Icons.lock, color: _customOrange),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _customOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _connectionStatus,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
