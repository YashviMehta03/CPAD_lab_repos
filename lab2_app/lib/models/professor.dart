class Professor {
  final String id;
  final String name;
  final String department;
  final String mainSubject;
  final List<String> subjects;
  final String room;
  final String officeHours;
  final String email;

  const Professor({
    required this.id,
    required this.name,
    required this.department,
    required this.mainSubject,
    required this.subjects,
    required this.room,
    required this.officeHours,
    required this.email,
  });
}
