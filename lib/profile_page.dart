import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ================= PROFILE HEADER =================
            CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage('assets/profile_placeholder.png'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Md. Jakaria',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Committee Member',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // ================= BASIC INFO =================
            _sectionTitle('Basic Information'),
            _infoTile('Full Name (BN)', 'মোঃ জাকারিয়া'),
            _infoTile('Member Type', 'Committee'),
            _infoTile('Position', 'General Secretary'),
            _infoTile('Member Since', '2022'),

            // ================= PERSONAL =================
            _sectionTitle('Personal Information'),
            _infoTile('Gender', 'Male'),
            _infoTile('Date of Birth', '01 Jan 2000'),

            // ================= CONTACT =================
            _sectionTitle('Contact Information'),
            _infoTile('Mobile', '01XXXXXXXXX'),
            _infoTile('Alternative Mobile', '01XXXXXXXXX'),
            _infoTile('Present Address', 'Dhaka'),
            _infoTile('Permanent Address', 'Pabna'),
            _infoTile('District', 'Pabna'),
            _infoTile('Upazila', 'Ishwardi'),
            _infoTile('Facebook', 'facebook.com/username'),
            _infoTile('WhatsApp', '+8801XXXXXXXXX'),

            // ================= BLOOD =================
            _sectionTitle('Blood & Donation'),
            _infoTile('Blood Group', 'O+'),
            _infoTile('Last Donation', '12 Dec 2024'),
            _infoTile('Total Donations', '5'),
            _infoTile('Eligible', 'Yes'),
            _infoTile('Preferred Location', 'Dhaka Medical'),

            // ================= EDUCATION =================
            _sectionTitle('Education'),
            _infoTile('School', 'ABC High School'),
            _infoTile('College', 'XYZ College'),
            _infoTile('University', 'AUST'),
            _infoTile('Department', 'CSE'),
            _infoTile('Student ID', '2020-1-60-XXX'),
            _infoTile('Current Year', '4'),
            _infoTile('Semester', '8'),

            // ================= BIO =================
            _sectionTitle('About Me'),
            _infoTile('Short Bio', 'Passionate social worker & developer'),
            _infoTile('Why Joined', 'To help people'),
            _infoTile('Future Goals', 'Serve society with technology'),
            _infoTile('Hobbies', 'Coding, Volunteering'),

            // ================= SOCIAL =================
            _sectionTitle('Social & Portfolio'),
            _infoTile('Portfolio', 'jakaria.dev'),

            // ================= SYSTEM =================
            _sectionTitle('System Info'),
            _infoTile('Account Status', 'Active'),
            _infoTile('Created Date', '01 Jan 2022'),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  // ================= INFO TILE =================
  Widget _infoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
