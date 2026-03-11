// lib/screens/student_details_page.dart
import 'package:flutter/material.dart';
import 'package:cublink/widgets/student_info_card.dart';

class StudentDetailsPage extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final String schoolName;
  final String registerNumber;
  final String contactNumber;
  final String guardianName;

  const StudentDetailsPage({
    super.key,
    required this.studentName,
    required this.studentClass,
    required this.schoolName,
    required this.registerNumber,
    required this.contactNumber, 
    required this.guardianName,
  });

  @override
  Widget build(BuildContext context) {
    // Just return the card content!
    return Center(
      child: SingleChildScrollView(
        // Add plenty of bottom padding so the Nav Bar doesn't cover the text
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        child: StudentInfoCard(
          name: studentName,
          className: studentClass,
          school: schoolName,
          regNo: registerNumber,
          contact: contactNumber,
          guardianName: guardianName,
        ),
      ),
    );
  }
}