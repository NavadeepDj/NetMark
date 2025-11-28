import 'package:flutter/material.dart';
import 'head_count_screen.dart';

class ClassAttendanceScreen extends StatefulWidget {
  final String className;
  final String section;
  final int studentCount;

  const ClassAttendanceScreen({
    super.key,
    required this.className,
    required this.section,
    required this.studentCount,
  });

  @override
  _ClassAttendanceScreenState createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Ethan Harper',
      'id': '12345',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfO2wSisEkluqhxcHVVI0zW79DmByokPwwdoodFOcuabYXA9tNfVPCk9Nt0WydsSbEKEFRFR6VGcDMG0h2CLFZLUzVhK7Vi8_uqddnqKmLvHfmQFxt8VmkDPMp4tZCs3ZnunlNslNfGJBVgi7vnRX05ofKP467UpJFnbgnO9ddx_Tmakt0DxBg29CzJeXchA8wWxU7Y-VHe5S-gs5o3NRP4Pb6fX8TVLOS8pZigu-StPXMhQ5G-3wjAEC4bKSUAxthHOF7Nh_-mDk',
      'isPresent': true,
    },
    {
      'name': 'Olivia Bennett',
      'id': '67890',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDkczZHaswgunHtQ-ZKMsnH5Dm-BVj4Mx9ayqg4l18vZyQyWv6Z3w3l7E_xBjX9mPunJqOaBvHK3kNlBomtEJAzC_c3batXjyQmaI_pU8mnj6RFJ0XTLCfGbiTyuJs8eFaldgfyd_nvWx1-3vE-DDjl85_OoDBaAvox8_myX8p1y0UGR9b8iQeNSPwoqzvY-XjjWNCi--omdcuyn546Okr73Da7wLWjVZBwjY4ItHN9DSqKB2I_rUsR2QzxFNf6Lv21jYWVb4kgYpc',
      'isPresent': true,
    },
    {
      'name': 'Noah Carter',
      'id': '24680',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDOqqg9MHHxE9VHKFo33KIEeN3yiaRW0-af3rDnIZ-jtiumUHoB73DWeCjlHYa4RpVmN3N45r6kzOp-675KSxzHpxuCwsrqQd81iR_f5i70xommGK8fF-IhU8USh1FuH6_qSogR6poNsX7__yb25s4CDD6qabNW_wto9GHsOVOMKWU6dCbOvyod517hXiPJOlmBm2cl9HNa-yOpuMK3jJHWj6G2U3v3lzNf_ltcZccRI9wmGXj-R17GvIf77lHtWeVmgNu5ss-1wYI',
      'isPresent': false,
    },
    {
      'name': 'Ava Mitchell',
      'id': '13579',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuC5X2Xr7tU1ZIJtaoho5fQmxTYPl9TqKY0hI6PtIIRWhaO8ZYIBc319y28gEEV-qvv5ZNSv8K33Nu6Sex9gzUnjhyD-3PTObIRn6AqG1cz-XACBNUjq0cQMrVsKv4vfRCAQJBlbCK_gEE1h26OW8vQvuJKG9In_eZ-ZvtcZeZDDw_yf51OVdcCMvIhxwnYeaBuroBOQNNRedw6v-LFquexg6OL44cBPc0jMeAysS4wpZbUV2nOXSpVSAWgOWQHi69WeXBY8QJ0aVIY',
      'isPresent': true,
    },
    {
      'name': 'Liam Foster',
      'id': '97531',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBfbG7rs-cLzJmVeZ30mWvQ5fK5QmIVNk9f1IhiT1KITtPKw1iY5ldEFzNWpd-7R9jJYJLwxnJP75havTYYkqd5K1b_tOYx90epvEm_N28mE0AtcuI3uB3Sej2vfoQ5mwIFgeeRDvUf2AEn4-bPY_iE3iImUYNqsneiDUWzE28zbrk2bQbbenOX1bY0PYhzaOIzy0leFdRlmIC76UuSEyUr3nwJKDhS1PhUIQYJg7S6Q4iXfrw3t7ZLEL6y0PvONyOGCY3YfKIx8Es',
      'isPresent': true,
    },
  ];

  int get presentCount => _students.where((student) => student['isPresent']).length;
  int get absentCount => _students.where((student) => !student['isPresent']).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0d1117), // Background color
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0d1117).withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF21262d), // Border color
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
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
                        // Settings button
                        GestureDetector(
                          onTap: () {
                            // Show settings
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.settings,
                              color: Color(0xFF7d8590), // Text secondary
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Course info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Course: ${widget.className}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFe6edf3), // Text primary
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Section: ${widget.section}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7d8590), // Text secondary
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 120), // Space for fixed footer
                  child: Column(
                    children: [
                      // Additional options at the top
                      Column(
                        children: [
                                                  _buildOptionCard(
                          icon: Icons.people,
                          title: "Head Count",
                          subtitle: "Manual count of students present",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HeadCountScreen(
                                  className: widget.className,
                                  section: widget.section,
                                ),
                              ),
                            );
                          },
                        ),
                          SizedBox(height: 16),
                          _buildOptionCard(
                            icon: Icons.verified,
                            title: "Cross Verification",
                            subtitle: "Verify via code or poll",
                            onTap: () {
                              // Navigate to cross verification
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Search and controls
                      Column(
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
                                hintText: "Search students...",
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
                          SizedBox(height: 16),
                          
                          // Controls row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enrolled Students (${widget.studentCount})",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7d8590), // Text secondary
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildControlButton("Mark All Present", () {
                                      setState(() {
                                        for (var student in _students) {
                                          student['isPresent'] = true;
                                        }
                                      });
                                    }),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildControlButton("Mark All Absent", () {
                                      setState(() {
                                        for (var student in _students) {
                                          student['isPresent'] = false;
                                        }
                                      });
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Student list
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xFF21262d), // Border color
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _students.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Color(0xFF21262d), // Border color
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return _buildStudentCard(student, index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0d1117), // Background color
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF21262d), // Border color
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$presentCount Present",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFe6edf3), // Text primary
                        ),
                      ),
                      Text(
                        "$absentCount Absent",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFe6edf3), // Text primary
                        ),
                      ),
                      Text(
                        "${widget.studentCount} Total",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFe6edf3), // Text primary
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Action buttons with icons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF161b22), // Card color
                            foregroundColor: Color(0xFFe6edf3), // Text primary
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Color(0xFF21262d), // Border color
                                width: 1,
                              ),
                            ),
                          ),
                          onPressed: () {
                            // Save draft
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border,
                                color: Color(0xFF7d8590), // Text secondary
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0b79ef), // Primary color
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Submit attendance
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Submit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF161b22), // Card color
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Color(0xFF21262d), // Border color
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF7d8590), // Text secondary
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Student image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: NetworkImage(student['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16),
          
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFe6edf3), // Text primary
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "ID: ${student['id']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7d8590), // Text secondary
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle switch
          Switch(
            value: student['isPresent'],
            onChanged: (value) {
              setState(() {
                student['isPresent'] = value;
              });
            },
            activeColor: Color(0xFF0b79ef), // Primary color
            activeTrackColor: Color(0xFF0b79ef).withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Color(0xFF161b22), // Card color
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF161b22), // Card color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF21262d), // Border color
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(0xFF7d8590), // Text secondary
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFe6edf3), // Text primary
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7d8590), // Text secondary
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF7d8590), // Text secondary
              size: 16,
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