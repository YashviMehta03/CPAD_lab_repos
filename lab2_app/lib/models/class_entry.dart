class ClassEntry {
  final String day; // e.g. "MON", "TUE"
  final String startTime;
  final String endTime;
  final String subject;
  final String professor;
  final String room;

  const ClassEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.professor,
    required this.room,
  });
}
