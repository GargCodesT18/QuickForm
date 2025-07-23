import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubmissionsPage extends StatefulWidget {
  const SubmissionsPage({super.key});

  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  List<dynamic> submissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    try {
      final response = await http.get(
        Uri.parse('https://raptor-absolute-possum.ngrok-free.app/fetch-users'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Added this header for ngrok
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        print('Parsed JSON: $parsed');

        // Make sure it's a list before assigning
        if (parsed is List) {
          setState(() {
            submissions = parsed;
            isLoading = false;
          });
          print('Successfully loaded ${submissions.length} submissions');
        } else {
          throw Exception("Expected a list but got: ${parsed.runtimeType}");
        }
      } else {
        // Better error handling
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error message';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Exception in fetchSubmissions: $e');
      setState(() {
        isLoading = false;
        submissions = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load submissions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    await fetchSubmissions();
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  String formatDob(dynamic isoString) {
    if (isoString == null || isoString
        .toString()
        .isEmpty) {
      return 'Not provided';
    }
    try {
      // Handle both ISO datetime strings and simple date strings
      String dateStr = isoString.toString();
      DateTime parsedDate;

      if (dateStr.contains('T')) {
        // ISO datetime format
        parsedDate = DateTime.parse(dateStr).toLocal();
      } else {
        // Simple date format (YYYY-MM-DD)
        parsedDate = DateTime.parse(dateStr);
      }

      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print('Date parsing error: $e for value: $isoString');
      return isoString.toString();
    }
  }

  Widget _buildCard(Map<String, dynamic> data, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[100]!, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(16),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[50],
              child: Text('${index + 1}',
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.w600)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['full_name']?.toString() ?? 'Unknown User',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    data['email']?.toString() ?? 'No email',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _buildInfoRow('Email:', data['email']?.toString()),
                _buildInfoRow(
                    'Country Code:', data['country_code']?.toString()),
                _buildInfoRow('Phone:', data['phone']?.toString()),
                _buildInfoRow('DOB:', formatDob(data['dob'])),
                _buildInfoRow('Gender:', data['gender']?.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Form Submissions'),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        actions: [
          if (!isLoading)
            IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          if (!isLoading && submissions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Text(
                'Total: ${submissions.length} submissions',
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.blue[700]),
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading submissions...'),
                ],
              ),
            )
                : submissions.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No submissions found',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[600])),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: submissions.length,
                itemBuilder: (context, index) =>
                    _buildCard(submissions[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}