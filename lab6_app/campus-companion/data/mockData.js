export const mockTimetable = {
  MON: [
    { id: '1', startTime: '09:30', endTime: '11:25', subject: 'CPAD Lab (Batch A & B)', professor: 'Prof. Pragati Vaishnav', room: 'Lab 1A' },
    { id: '2', startTime: '11:30', endTime: '12:25', subject: 'PE III – PANS', professor: 'Dr. Varshapriya J N', room: 'AL 202' },
    { id: '3', startTime: '12:30', endTime: '13:25', subject: 'PE III – Software Testing', professor: 'Prof. Shreekant Bedekar', room: 'AL 004' },
    { id: '4', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Pragati Vaishnav', room: 'AL 302' },
    { id: '5', startTime: '15:30', endTime: '16:25', subject: 'MDM V DS Lab', professor: 'Prof. Pragati Vaishnav', room: 'Lab 1B' },
  ],
  TUE: [
    { id: '6', startTime: '09:30', endTime: '10:25', subject: 'PE IV – Deep Learning Lab', professor: 'Prof. Harshala C Dalal', room: 'Lab 1B' },
    { id: '7', startTime: '10:30', endTime: '11:25', subject: 'PE IV – Quantum Computing Lab', professor: 'Dr. S. T. Shingade', room: 'Lab 1A' },
    { id: '8', startTime: '11:30', endTime: '12:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202' },
    { id: '9', startTime: '12:30', endTime: '13:25', subject: 'PE III – PANS', professor: 'Dr. Varshapriya J N', room: 'AL 202' },
    { id: '10', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Pragati Vaishnav', room: 'AL 207' },
    { id: '11', startTime: '15:30', endTime: '16:25', subject: 'CPAD Lab (Batch C & D)', professor: 'Prof. Mandar K. Sase', room: 'Internet Lab' },
  ],
  WED: [
    { id: '12', startTime: '09:30', endTime: '11:25', subject: 'PE III – Software Testing Lab', professor: 'Prof. Shreekant Bedekar', room: 'Lab 3B' },
    { id: '13', startTime: '11:30', endTime: '12:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 202' },
    { id: '14', startTime: '12:30', endTime: '13:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202' },
    { id: '15', startTime: '14:30', endTime: '15:25', subject: 'MDM V – Data Science', professor: 'Prof. Ankit Nimbolkar', room: 'AL 207' },
    { id: '16', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004' },
    { id: '17', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202' },
  ],
  THU: [
    { id: '18', startTime: '10:30', endTime: '11:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 004' },
    { id: '19', startTime: '11:30', endTime: '12:25', subject: 'Data Management', professor: 'Prof. Riddhi Patil', room: 'AL 004' },
    { id: '20', startTime: '12:30', endTime: '13:25', subject: 'PE IV – Deep Learning', professor: 'Prof. Harshala C Dalal', room: 'AL 202' },
    { id: '21', startTime: '14:30', endTime: '15:25', subject: 'Project', professor: 'Project Guide', room: 'Project Lab' },
    { id: '22', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004' },
    { id: '23', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202' },
  ],
  FRI: [
    { id: '24', startTime: '09:30', endTime: '10:25', subject: 'Honors BC Lab', professor: 'Dr. M. R. Shirole', room: 'Lab 1B' },
    { id: '25', startTime: '11:30', endTime: '12:25', subject: 'PE III – PANS Lab', professor: 'Dr. Varshapriya J N', room: 'Lab 1A' },
    { id: '26', startTime: '14:30', endTime: '15:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004' },
    { id: '27', startTime: '15:30', endTime: '16:25', subject: 'Open Elective II', professor: 'TBD', room: 'AL 004' },
    { id: '28', startTime: '16:30', endTime: '17:25', subject: 'Honors – Blockchain', professor: 'Dr. M. R. Shirole', room: 'AL 202' },
  ]
};

export const mockProfessors = [
  { id: 'p1', name: 'Prof. Riddhi Patil', department: 'Computer Engineering', room: 'AL 004, CE Dept.', email: 'riddhi.patil@vjti.ac.in', subjects: ['Data Management'] },
  { id: 'p2', name: 'Prof. Harshala C Dalal', department: 'Computer Engineering', room: 'AL 202, CE Dept.', email: 'harshala.dalal@vjti.ac.in', subjects: ['Deep Learning'] },
  { id: 'p3', name: 'Dr. Varshapriya J N', department: 'Computer Engineering', room: 'AL 202, CE Dept.', email: 'varshapriya.jn@vjti.ac.in', subjects: ['PANS'] },
  { id: 'p4', name: 'Prof. Shreekant Bedekar', department: 'Computer Engineering', room: 'AL 004, CE Dept.', email: 'shreekant.bedekar@vjti.ac.in', subjects: ['Software Testing'] },
  { id: 'p5', name: 'Prof. Pragati Vaishnav', department: 'Computer Engineering', room: 'Lab 1A, CE Dept.', email: 'pragati.vaishnav@vjti.ac.in', subjects: ['CPAD Lab'] },
  { id: 'p6', name: 'Dr. M. R. Shirole', department: 'Computer Engineering', room: 'AL 202, CE Dept.', email: 'mr.shirole@vjti.ac.in', subjects: ['Blockchain'] },
  { id: 'p7', name: 'Prof. Mandar K. Sase', department: 'Computer Engineering', room: 'Internet Lab, CE Dept.', email: 'mandar.sase@vjti.ac.in', subjects: ['CPAD Lab'] },
  { id: 'p8', name: 'Dr. S. T. Shingade', department: 'Computer Engineering', room: 'Lab 1A, CE Dept.', email: 'st.shingade@vjti.ac.in', subjects: ['Quantum Computing'] },
  { id: 'p9', name: 'Prof. Ankit Nimbolkar', department: 'Computer Engineering', room: 'AL 004, CE Dept.', email: 'ankit.nimbolkar@vjti.ac.in', subjects: ['Data Science'] }
];

export const mockEvents = [
  { id: 'e1', title: 'Tech Symposium 2026', category: 'Tech', date: '24 August 2026', location: 'Main Auditorium' },
  { id: 'e2', title: 'Cultural Fest – Utsav', category: 'Cultural', date: '30 August 2026', location: 'Open Air Theatre' },
  { id: 'e3', title: 'Hackathon – BuildIt', category: 'Hackathon', date: '5 September 2026', location: 'CS Block, Labs 1–4' },
  { id: 'e4', title: 'Campus Placement Drive', category: 'Placement', date: '12 September 2026', location: 'Seminar Hall A' },
  { id: 'e5', title: 'Research Paper Workshop', category: 'Academic', date: '20 September 2026', location: 'Conference Room, Admin Block' }
];
