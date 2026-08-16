import 'package:flutter/material.dart';
import '../models/professor.dart';
import '../models/class_entry.dart';
import '../models/event.dart';

class MockData {
  // ─── Professors ────────────────────────────────────────────────────────────

  static const List<Professor> professors = [
    Professor(
      id: 'p1',
      name: 'Prof. Riddhi Patil',
      department: 'Computer Engineering',
      mainSubject: 'Data Management',
      subjects: ['Data Management', 'Database Systems', 'Big Data Analytics'],
      room: 'AL 004, CE Dept.',
      officeHours: 'Wed & Thu · 10:30 AM – 12:25 PM',
      email: 'riddhi.patil@vjti.ac.in',
    ),
    Professor(
      id: 'p2',
      name: 'Prof. Harshala C Dalal',
      department: 'Computer Engineering',
      mainSubject: 'PE IV – Deep Learning',
      subjects: ['Deep Learning', 'Neural Networks', 'Computer Vision'],
      room: 'AL 202, CE Dept.',
      officeHours: 'Tue & Wed · 11:30 AM – 12:25 PM',
      email: 'harshala.dalal@vjti.ac.in',
    ),
    Professor(
      id: 'p3',
      name: 'Dr. Varshapriya J N',
      department: 'Computer Engineering',
      mainSubject: 'PE III – PANS',
      subjects: ['Parallel & Network Systems', 'Distributed Computing', 'High Performance Computing'],
      room: 'AL 202, CE Dept.',
      officeHours: 'Mon, Tue & Fri · 11:30 AM – 12:25 PM',
      email: 'varshapriya.jn@vjti.ac.in',
    ),
    Professor(
      id: 'p4',
      name: 'Prof. Shreekant Bedekar',
      department: 'Computer Engineering',
      mainSubject: 'PE III – Software Testing',
      subjects: ['Software Testing', 'QA Automation', 'Agile & DevOps'],
      room: 'AL 004, CE Dept.',
      officeHours: 'Mon & Tue · 12:30 PM – 1:25 PM',
      email: 'shreekant.bedekar@vjti.ac.in',
    ),
    Professor(
      id: 'p5',
      name: 'Prof. Pragati Vaishnav',
      department: 'Computer Engineering',
      mainSubject: 'Cross Platform App Dev Lab',
      subjects: ['Flutter & Dart', 'Cross Platform App Development', 'MDM V DS'],
      room: 'Lab 1A, CE Dept.',
      officeHours: 'Mon & Tue · 9:30 AM – 11:25 AM',
      email: 'pragati.vaishnav@vjti.ac.in',
    ),
    Professor(
      id: 'p6',
      name: 'Dr. M. R. Shirole',
      department: 'Computer Engineering',
      mainSubject: 'Honors – Blockchain',
      subjects: ['Blockchain Technology', 'Augmented & Virtual Reality', 'Distributed Ledger'],
      room: 'AL 202, CE Dept.',
      officeHours: 'Wed, Thu & Fri · 4:30 PM – 5:25 PM',
      email: 'mr.shirole@vjti.ac.in',
    ),
    Professor(
      id: 'p7',
      name: 'Prof. Mandar K. Sase',
      department: 'Computer Engineering',
      mainSubject: 'Cross Platform App Dev Lab',
      subjects: ['Mobile App Development', 'Flutter', 'React Native'],
      room: 'Internet Lab, CE Dept.',
      officeHours: 'Tue · 3:30 PM – 4:25 PM',
      email: 'mandar.sase@vjti.ac.in',
    ),
    Professor(
      id: 'p8',
      name: 'Dr. S. T. Shingade',
      department: 'Computer Engineering',
      mainSubject: 'PE IV – Quantum Computing',
      subjects: ['Quantum Computing', 'Quantum Algorithms', 'Quantum Cryptography'],
      room: 'Lab 1A, CE Dept.',
      officeHours: 'Tue · 10:30 AM – 11:25 AM',
      email: 'st.shingade@vjti.ac.in',
    ),
    Professor(
      id: 'p9',
      name: 'Prof. Ankit Nimbolkar',
      department: 'Computer Engineering',
      mainSubject: 'MDM V Data Science',
      subjects: ['Data Science', 'Machine Learning', 'Statistical Analysis'],
      room: 'AL 004, CE Dept.',
      officeHours: 'Mon–Wed · 2:30 PM – 3:25 PM',
      email: 'ankit.nimbolkar@vjti.ac.in',
    ),
  ];

  // ─── Timetable ─────────────────────────────────────────────────────────────

  // AY 2026-27 ODD Semester – Final BTech (CE), VJTI Mumbai-19
  static const List<ClassEntry> timetable = [
    // Monday
    ClassEntry(day: 'MON', startTime: '09:30', endTime: '11:25', subject: 'CPAD Lab (Batch A & B)', professor: 'Prof. Pragati Vaishnav', room: 'Lab 1A'),
    ClassEntry(day: 'MON', startTime: '11:30', endTime: '12:25', subject: 'PE III – PANS', professor: 'Dr. Varshapriya J N', room: 'AL 202'),
    ClassEntry(day: 'MON', startTime: '12:30', endTime: '13:25', subject: 'PE III – Software Testing', professor: 'Prof. Shreekant Bedekar', room: 'AL 004'),
    ClassEntry(day: 'MON', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Pragati Vaishnav', room: 'AL 302'),
    ClassEntry(day: 'MON', startTime: '15:30', endTime: '16:25', subject: 'MDM V DS Lab', professor: 'Prof. Pragati Vaishnav', room: 'Lab 1B'),

    // Tuesday
    ClassEntry(day: 'TUE', startTime: '09:30', endTime: '10:25', subject: 'PE IV – Deep Learning Lab', professor: 'Prof. Harshala C Dalal', room: 'Lab 1B'),
    ClassEntry(day: 'TUE', startTime: '10:30', endTime: '11:25', subject: 'PE IV – Quantum Computing Lab', professor: 'Dr. S. T. Shingade', room: 'Lab 1A'),
    ClassEntry(day: 'TUE', startTime: '11:30', endTime: '12:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202'),
    ClassEntry(day: 'TUE', startTime: '12:30', endTime: '13:25', subject: 'PE III – PANS', professor: 'Dr. Varshapriya J N', room: 'AL 202'),
    ClassEntry(day: 'TUE', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Pragati Vaishnav', room: 'AL 207'),
    ClassEntry(day: 'TUE', startTime: '15:30', endTime: '16:25', subject: 'CPAD Lab (Batch C & D)', professor: 'Prof. Mandar K. Sase', room: 'Internet Lab'),

    // Wednesday
    ClassEntry(day: 'WED', startTime: '09:30', endTime: '11:25', subject: 'PE III – Software Testing Lab', professor: 'Prof. Shreekant Bedekar', room: 'Lab 3B'),
    ClassEntry(day: 'WED', startTime: '11:30', endTime: '12:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 202'),
    ClassEntry(day: 'WED', startTime: '12:30', endTime: '13:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202'),
    ClassEntry(day: 'WED', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Ankit Nimbolkar', room: 'AL 207'),
    ClassEntry(day: 'WED', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004'),
    ClassEntry(day: 'WED', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202'),

    // Thursday
    ClassEntry(day: 'THU', startTime: '10:30', endTime: '11:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 004'),
    ClassEntry(day: 'THU', startTime: '11:30', endTime: '12:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 004'),
    ClassEntry(day: 'THU', startTime: '12:30', endTime: '13:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202'),
    ClassEntry(day: 'THU', startTime: '14:30', endTime: '15:25', subject: 'Project', professor: 'Project Guide', room: 'Project Lab'),
    ClassEntry(day: 'THU', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004'),
    ClassEntry(day: 'THU', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202'),

    // Friday
    ClassEntry(day: 'FRI', startTime: '09:30', endTime: '10:25', subject: 'Honors BC Lab', professor: 'Dr. M. R. Shirole', room: 'Lab 1B'),
    ClassEntry(day: 'FRI', startTime: '11:30', endTime: '12:25', subject: 'PE III – PANS Lab', professor: 'Dr. Varshapriya J N', room: 'Lab 1A'),
    ClassEntry(day: 'FRI', startTime: '14:30', endTime: '15:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004'),
    ClassEntry(day: 'FRI', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004'),
    ClassEntry(day: 'FRI', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202'),
  ];

  static List<ClassEntry> getClassesForDay(String day) {
    return timetable.where((c) => c.day == day).toList();
  }

  // ─── Today's Classes (snapshot) ────────────────────────────────────────────

  static const List<ClassEntry> todayClasses = [
    ClassEntry(day: 'MON', startTime: '09:30', endTime: '11:25', subject: 'CPAD Lab (Batch A & B)', professor: 'Prof. Pragati Vaishnav', room: 'Lab 1A'),
    ClassEntry(day: 'MON', startTime: '11:30', endTime: '12:25', subject: 'PE III – PANS', professor: 'Dr. Varshapriya J N', room: 'AL 202'),
    ClassEntry(day: 'MON', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Pragati Vaishnav', room: 'AL 302'),
  ];

  // ─── Events ────────────────────────────────────────────────────────────────

  static final List<Event> events = [
    Event(
      id: 'e1',
      name: 'Tech Symposium 2026',
      date: '24 August 2026',
      time: '10:00 AM',
      location: 'Main Auditorium',
      description: 'Technology talks by industry experts, student project demonstrations, and panel discussions on emerging trends in AI, Cloud, and IoT.',
      category: 'Tech',
      icon: Icons.computer_outlined,
    ),
    Event(
      id: 'e2',
      name: 'Cultural Fest – Utsav',
      date: '30 August 2026',
      time: '05:00 PM',
      location: 'Open Air Theatre',
      description: 'Annual cultural fest featuring dance performances, music, drama, and various competitions. Celebrate talent from across all departments.',
      category: 'Cultural',
      icon: Icons.celebration_outlined,
    ),
    Event(
      id: 'e3',
      name: 'Hackathon – BuildIt',
      date: '5 September 2026',
      time: '09:00 AM',
      location: 'CS Block, Labs 1–4',
      description: '24-hour hackathon for students to build innovative solutions. Form teams of 3–4. Prizes worth ₹50,000 across multiple categories.',
      category: 'Hackathon',
      icon: Icons.code_outlined,
    ),
    Event(
      id: 'e4',
      name: 'Campus Placement Drive',
      date: '12 September 2026',
      time: '08:30 AM',
      location: 'Seminar Hall A',
      description: 'On-campus placement drive with top companies in software engineering, product management, and data science roles. Register via placement portal.',
      category: 'Placement',
      icon: Icons.work_outline,
    ),
    Event(
      id: 'e5',
      name: 'Research Paper Workshop',
      date: '20 September 2026',
      time: '02:00 PM',
      location: 'Conference Room, Admin Block',
      description: 'Workshop on writing and publishing academic research papers. Learn about IEEE and Springer formats, submission guidelines, and peer review process.',
      category: 'Academic',
      icon: Icons.article_outlined,
    ),
  ];
}
