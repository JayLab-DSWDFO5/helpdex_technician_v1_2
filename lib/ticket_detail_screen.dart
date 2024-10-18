import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'closed_tickets_page.dart';
import 'main.dart';
import 'config.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Map<String, dynamic> _ticket; // Local variable to hold ticket data
  Timer? _timer;
  late DateTime _startTime;
  int _elapsedTime = 0;
  final TextEditingController _resolutionNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket; // Initialize with the widget's ticket
    _initializeStartTime();
    if (_ticket['status'] == 'In Progress') {
      _startElapsedTimeCounter();
    }
    // Start the auto-update timer
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchLatestTicketData();
    });
  }

  @override
  void dispose() {
    _stopElapsedTimeCounter();
    _resolutionNotesController.dispose();
    super.dispose();
  }

  void _initializeStartTime() {
    if (_ticket['start_time'] != null) {
      _startTime = DateTime.parse(_ticket['start_time']);
      _updateElapsedTime();
    } else {
      _startTime = DateTime.now();
    }
  }

  void _updateElapsedTime() {
    _elapsedTime = DateTime.now().difference(_startTime).inSeconds;
  }

  void _startElapsedTimeCounter() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateElapsedTime();
      });
    });
  }

  void _stopElapsedTimeCounter() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _completeTask() async {
    if (_resolutionNotesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter resolution notes before completing the task')),
      );
      return;
    }

    final payload = {
      'request_tracker': _ticket['request_tracker'],
      'status': 'Completed',
      'completion_time': DateTime.now().toIso8601String(),
      'resolution_notes': _resolutionNotesController.text,
    };

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/mobile/completeTask.php'),
      body: json.encode(payload),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _ticket['status'] = 'Completed';
        _stopElapsedTimeCounter();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task completed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete task: ${response.body}')),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _resolutionNotesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter resolution notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeTask();
              },
              child: Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  void _fetchLatestTicketData() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/mobile/getTicket.php?request_tracker=${_ticket['request_tracker']}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _ticket = json.decode(response.body); // Update the local variable
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch latest ticket data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchLatestTicketData, // Call the fetch method
            tooltip: 'Reload',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Ticket #${_ticket['request_tracker']}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple, Colors.indigo],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.confirmation_number,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusAndPriority(_ticket['status'], _ticket['priority']),
                  SizedBox(height: 24),
                  _buildDetailSection('Ticket Information', [
                    _buildDetailItem(Icons.category, 'Service Type', _ticket['service_type']),
                    _buildDetailItem(Icons.location_on, 'Location', '${_ticket['office_name']}\n${_ticket['office_location']}\n${_ticket['office_type']}'),
                    _buildDetailItem(Icons.person, 'Requester', '${_ticket['requester_name']}\n${_ticket['requester_email']}'),
                    _buildDetailItem(Icons.group, 'Requesting For', _ticket['requesting_for']),
                    _buildDetailItem(Icons.calendar_today, 'Date Created', _ticket['request_createdatetime']),
                    if (_ticket['start_time'] != null)
                      _buildDetailItem(Icons.access_time, 'Start Time', _ticket['start_time']),
                  ]),
                  _ticket['request_attachments'] != null && _ticket['request_attachments'].isNotEmpty
                    ? _buildDetailSection('Attachments', [
                        _buildDetailItem(Icons.attachment, 'Attachments', _ticket['request_attachments']),
                      ])
                    : SizedBox.shrink(),
                  SizedBox(height: 24),
                  _buildDetailSection('From Client', [
                    _buildDetailItem(Icons.description, 'Clients Message', _ticket['request_message']),
                  ]),
                  SizedBox(height: 24),
                  _buildDetailSection('Additional Information', [
                    _buildDetailItem(Icons.summarize, 'Summary', _ticket['summary']),
                    _buildDetailItem(Icons.note, 'Triage Notes', _ticket['triage_notes']),
                    _buildDetailItem(Icons.note, 'Resolution Notes', _ticket['resolution_notes'] ?? 'No resolution notes available'),
                    _buildDetailItem(Icons.attachment, 'Attachments', _ticket['request_attachments'] != null && _ticket['request_attachments'].isNotEmpty ? _ticket['request_attachments'].map((attachment) => attachment.toString()).join('\n') : 'No attachments'),
                  ]),
                  
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _ticket['status'] != 'Completed' ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 60,
            child: FloatingActionButton.extended(
              onPressed: () async {
                if (_ticket['status'] != 'In Progress') {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}/mobile/startTask.php'),
                    body: json.encode({
                      'request_tracker': _ticket['request_tracker'],
                      'status': 'In Progress',
                      'start_time': DateTime.now().toIso8601String(),
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      _ticket['status'] = 'In Progress';
                      _ticket['start_time'] = DateTime.now().toIso8601String();
                      _initializeStartTime();
                    });
                    _startElapsedTimeCounter();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status')),
                    );
                  }
                } else {
                  _showCompletionDialog();
                }
              },
              icon: Icon(_ticket['status'] == 'In Progress' ? Icons.check : Icons.play_arrow, size: 30),
              label: Text(
                _ticket['status'] == 'In Progress'
                  ? 'Complete Task'
                  : 'Start Task',
                style: TextStyle(fontSize: 20)
              ),
              backgroundColor: _ticket['status'] == 'In Progress' ? Colors.orange : Colors.green,
              heroTag: 'mainButton',
            ),
          ),
        ],
      ) : null,
    );
  }

  Widget _buildStatusAndPriority(String status, String priority) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Chip(
          label: Text(status, style: TextStyle(color: Colors.white)),
          backgroundColor: _getStatusColor(status),
        ),
        Chip(
          label: Text(priority, style: TextStyle(color: Colors.white)),
          backgroundColor: _getPriorityColor(priority),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                ),
                SizedBox(height: 4),
                Text(
                  value?.toString() ?? 'N/A',
                  style: TextStyle(fontSize: 14)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
