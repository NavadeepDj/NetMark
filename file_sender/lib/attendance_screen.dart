import 'package:flutter/material.dart';
import 'class_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117), // Background color
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0D1117).withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF21262d), // Border color
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xFF7d8590), // Text secondary
                          size: 24,
                        ),
                      ),
                    ),
                    // Title
                    Expanded(
                      child: Text(
                        "Attendance",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFe6edf3), // Text primary
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Spacer
                    SizedBox(width: 32),
                  ],
                ),
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Search section
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search input
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF010409), // Input background
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: Color(0xFFe6edf3), // Text primary
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search students by name or ID...",
                                hintStyle: TextStyle(
                                  color: Color(0xFF7d8590), // Text secondary
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF7d8590), // Text secondary
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Classes section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Classes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFe6edf3), // Text primary
                            ),
                          ),
                          SizedBox(height: 12),

                          // Class cards
                          _buildClassCard(
                            className: "Introduction to Programming",
                            section: "Section A",
                            studentCount: 34,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClassAttendanceScreen(
                                    className: "Introduction to Programming",
                                    section: "Section A",
                                    studentCount: 34,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),

                                                     _buildClassCard(
                             className: "Data Structures and Algorithms",
                             section: "Section B",
                             studentCount: 42,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => ClassAttendanceScreen(
                                     className: "Data Structures and Algorithms",
                                     section: "Section B",
                                     studentCount: 42,
                                   ),
                                 ),
                               );
                             },
                           ),
                          SizedBox(height: 12),

                                                     _buildClassCard(
                             className: "Web Development",
                             section: "Section A",
                             studentCount: 28,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => ClassAttendanceScreen(
                                     className: "Web Development",
                                     section: "Section A",
                                     studentCount: 28,
                                   ),
                                 ),
                               );
                             },
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard({
    required String className,
    required String section,
    required int studentCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF161B22), // Card color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF21262d), // Border color
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Class info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFe6edf3), // Text primary
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    section,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7d8590), // Text secondary
                    ),
                  ),
                ],
              ),
            ),

            // Student count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  studentCount.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFe6edf3), // Text primary
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Students",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7d8590), // Text secondary
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
