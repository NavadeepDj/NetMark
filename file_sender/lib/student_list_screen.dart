import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'config.dart';

class StudentListScreen extends StatefulWidget {
  final bool showPresent;
  final bool showAbsent;

  const StudentListScreen({
    super.key,
    this.showPresent = false,
    this.showAbsent = false,
  });

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  List<dynamic> _students = [];
  bool _isLoading = true;
  String _error = '';

  // List of colors for initials
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _logger.i('Initializing StudentListScreen');
    _logger.d(
        'Show Present: ${widget.showPresent}, Show Absent: ${widget.showAbsent}');
    _fetchStudents();
  }

  Color _getColorForInitial(String initial) {
    return _colors[initial.codeUnitAt(0) % _colors.length];
  }

  Future<void> _fetchStudents() async {
    _logger.i('Fetching students list');
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse('${Config.serverUrl}/students'),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d('Received ${data['students'].length} students from server');

        // Log the raw student data for debugging
        _logger.d('Raw student data: ${data['students']}');

        setState(() {
          _students = data['students'].where((student) {
            _logger.d(
                'Checking student: ${student['name']} - Present: ${student['isPresent']}');
            if (widget.showPresent) return student['isPresent'] == true;
            if (widget.showAbsent) return student['isPresent'] == false;
            return true;
          }).toList();
        });

        _logger.i(
            'Filtered to ${_students.length} students based on present/absent criteria');
      } else {
        _logger.e('Failed to load students - Status: ${response.statusCode}',
            error: response.body);
        setState(() {
          _error = 'Failed to load students (${response.statusCode})';
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetching students', error: e, stackTrace: stackTrace);
      setState(() {
        _error = 'Connection error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) {
      _logger.d('Empty search query, fetching all students');
      _fetchStudents();
      return;
    }

    _logger.i('Searching students with query: $query');
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse('${Config.serverUrl}/search_students/$query'),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d('Received ${data['students'].length} students from search');

        // Log the raw student data for debugging
        _logger.d('Raw search student data: ${data['students']}');

        setState(() {
          _students = data['students'].where((student) {
            _logger.d(
                'Checking student: ${student['name']} - Present: ${student['isPresent']}');
            if (widget.showPresent) return student['isPresent'] == true;
            if (widget.showAbsent) return student['isPresent'] == false;
            return true;
          }).toList();
        });

        _logger.i('Filtered to ${_students.length} students after search');
      } else {
        _logger.e('Search failed - Status: ${response.statusCode}',
            error: response.body);
        setState(() {
          _error = 'Search failed (${response.statusCode})';
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error during search', error: e, stackTrace: stackTrace);
      setState(() {
        _error = 'Connection error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "All Students";
    if (widget.showPresent) title = "Present Students";
    if (widget.showAbsent) title = "Absent Students";

    _logger.d('Building StudentListScreen with title: $title');

    return Scaffold(
      backgroundColor: Color(0xFF111827), // Dark background
      appBar: AppBar(
        backgroundColor: Color(0xFF1f2937), // Dark app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFd1d5db)),
          onPressed: () {
            _logger.d('Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: Text(
          "KARE FAST · $title",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFf9fafb), // White text
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF111827), Color(0xFF0f172a)],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1f2937),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Color(0xFFf9fafb),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or registration number',
                      hintStyle: TextStyle(
                        color: Color(0xFF6b7280),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Color(0xFF9ca3af),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: _searchStudents,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3b82f6),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading students...',
                              style: TextStyle(
                                color: Color(0xFF9ca3af),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error.isNotEmpty
                        ? Center(
                            child: Container(
                              margin: EdgeInsets.all(24),
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Color(0xFF1f2937),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFef4444).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFef4444),
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _error,
                                    style: TextStyle(
                                      color: Color(0xFFef4444),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _students.isEmpty
                            ? Center(
                                child: Container(
                                  margin: EdgeInsets.all(24),
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1f2937),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color(0xFF6b7280).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        color: Color(0xFF6b7280),
                                        size: 48,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No students found',
                                        style: TextStyle(
                                          color: Color(0xFF9ca3af),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _students.length,
                                itemBuilder: (context, index) {
                                  final student = _students[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1f2937),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: student['isPresent']
                                            ? Color(0xFF10b981).withOpacity(0.3)
                                            : Color(0xFFef4444)
                                                .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              _getColorForInitial(
                                                  student['initial']),
                                              _getColorForInitial(
                                                      student['initial'])
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getColorForInitial(
                                                      student['initial'])
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            student['initial'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFf9fafb),
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        student['registrationNumber'],
                                        style: TextStyle(
                                          color: Color(0xFF9ca3af),
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: student['isPresent']
                                              ? Color(0xFF10b981)
                                                  .withOpacity(0.1)
                                              : Color(0xFFef4444)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          student['isPresent']
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: student['isPresent']
                                              ? Color(0xFF10b981)
                                              : Color(0xFFef4444),
                                          size: 24,
                                        ),
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

  @override
  void dispose() {
    _logger.d('Disposing StudentListScreen');
    _searchController.dispose();
    super.dispose();
  }
}
