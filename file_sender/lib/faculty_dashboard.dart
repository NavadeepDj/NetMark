import 'package:flutter/material.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  _FacultyDashboardState createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111827), // Background color
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  SizedBox(width: 40), // Spacer
                  Expanded(
                    child: Text(
                      "Faculty Dashboard",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFf9fafb), // Text primary
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40), // Spacer
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: GridView.count(
                  crossAxisCount: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 3.5,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.person,
                      title: "My Profile",
                      subtitle: "View and edit your profile",
                      onTap: () {
                        // Navigate to profile
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.edit,
                      title: "Take Attendance",
                      subtitle: "Mark student attendance",
                      onTap: () {
                        Navigator.pushNamed(context, '/attendance');
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.book,
                      title: "Class Section Details",
                      subtitle: "View your assigned sections",
                      onTap: () {
                        // Navigate to class sections
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.pie_chart,
                      title: "Analytics",
                      subtitle: "Track attendance and metrics",
                      onTap: () {
                        // Navigate to analytics
                      },
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1f2937), // Accent color
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFF312e81).withOpacity(0.5), // Indigo 900/50
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF818cf8), // Primary color
                    size: 32,
                  ),
                ),
                SizedBox(width: 20),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFf9fafb), // Text primary
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFd1d5db), // Text secondary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
