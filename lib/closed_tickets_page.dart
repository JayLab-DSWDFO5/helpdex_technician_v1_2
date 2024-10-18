import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ticket_detail_screen.dart';
import 'custom_navigation_bar.dart';
import 'home_screen.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'config.dart';

class ClosedTicketsPage extends StatefulWidget {
  final int techId;
  final Map<String, dynamic> technicianData;

  const ClosedTicketsPage({
    Key? key,
    required this.techId,
    required this.technicianData,
  }) : super(key: key);

  @override
  _ClosedTicketsPageState createState() => _ClosedTicketsPageState();
}

class _ClosedTicketsPageState extends State<ClosedTicketsPage> {
  List<Map<String, dynamic>> _closedTickets = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 1; // Set to 1 for ClosedTicketsPage

  @override
  void initState() {
    super.initState();
    _fetchClosedTickets();
  }

  Future<void> _fetchClosedTickets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final payload = {
        'tech_name': widget.technicianData['tech_name'],
      };

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/mobile/getClosedTickets.php'),
        body: json.encode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _closedTickets = List<Map<String, dynamic>>.from(responseData['tickets']);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load closed tickets: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load closed tickets: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load closed tickets. Please try again.';
      });
    }
  }

  void _onTap(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      Widget newPage;
      switch (index) {
        case 0:
          newPage = HomeScreen(
            techId: widget.techId,
            technicianData: widget.technicianData,
          );
          break;
        case 1:
          return; // Stay on ClosedTicketsPage
        case 2:
          newPage = ProfilePage(
            name: widget.technicianData['tech_name'],
            email: widget.technicianData['tech_username'],
            techId: widget.techId,
          );
          break;
        case 3:
          newPage = SettingsPage(
            name: widget.technicianData['tech_name'],
            email: widget.technicianData['tech_username'],
            techId: widget.techId,
          );
          break;
        default:
          return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => newPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Closed Tickets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(234, 88, 12, 1),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchClosedTickets,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: const Color.fromRGBO(234, 88, 12, 1)))
          : _hasError
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : _closedTickets.isEmpty
                  ? Center(child: Text('No closed tickets available.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                  : ListView.builder(
                      itemCount: _closedTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _closedTickets[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(
                              ticket['request_tracker'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text('Status: ${ticket['status']}'),
                                Text('Resolution Notes: ${ticket['resolution_notes'] ?? 'N/A'}'),
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right, color: const Color.fromRGBO(234, 88, 12, 1)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketDetailScreen(ticket: ticket),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
