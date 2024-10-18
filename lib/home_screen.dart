import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_navigation_bar.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'ticket_detail_screen.dart';
import 'closed_tickets_page.dart';
import 'config.dart';

class HomeScreen extends StatefulWidget {
  final int techId;
  final Map<String, dynamic> technicianData;

  const HomeScreen({
    Key? key,
    required this.techId,
    required this.technicianData,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _assignedTickets = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final Color _customOrange = const Color.fromRGBO(234, 88, 12, 1);

  @override
  void initState() {
    super.initState();
    _fetchAssignedTickets();
  }

  Future<void> _fetchAssignedTickets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/mobile/getAssignedTickets.php'),
        body: json.encode({
          'assigned_it_person': widget.technicianData['tech_name'],
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _assignedTickets = List<Map<String, dynamic>>.from(responseData['tickets']);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load tickets: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load tickets. Please try again.';
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
          newPage = ClosedTicketsPage(
            techId: widget.techId,
            technicianData: widget.technicianData,
          );
          break;
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
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Assigned Tickets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _customOrange,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAssignedTickets,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _customOrange))
          : _hasError
              ? _buildErrorWidget()
              : _assignedTickets.isEmpty
                  ? _buildEmptyStateWidget()
                  : _buildTicketList(),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAssignedTickets,
            style: ElevatedButton.styleFrom(
              backgroundColor: _customOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tickets assigned yet.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      itemCount: _assignedTickets.length,
      itemBuilder: (BuildContext context, int index) {
        final ticket = _assignedTickets[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(ticket['priority']),
              child: Text(
                ticket['priority'][0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              ticket['request_tracker'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Status: ${ticket['status']}'),
                Text('Service: ${ticket['service_type']}'),
                Text('Location: ${ticket['request_location']}'),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: _customOrange),
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
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red[700]!;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
