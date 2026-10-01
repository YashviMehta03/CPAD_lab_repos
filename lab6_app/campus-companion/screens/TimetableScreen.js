import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { mockTimetable } from '../data/mockData';

const DAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

export default function TimetableScreen() {
  const [selectedDay, setSelectedDay] = useState('MON');
  const classes = mockTimetable[selectedDay] || [];

  return (
    <View style={styles.container}>
      {/* Day Selector */}
      <View style={styles.daySelectorRow}>
        {DAYS.map(day => (
          <TouchableOpacity 
            key={day} 
            style={[styles.dayChip, selectedDay === day && styles.dayChipActive]}
            onPress={() => setSelectedDay(day)}
          >
            <Text style={[styles.dayText, selectedDay === day && styles.dayTextActive]}>{day}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Class List */}
      <ScrollView>
        {classes.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>No classes scheduled for today! 🎉</Text>
          </View>
        ) : (
          classes.map(c => (
            <View key={c.id} style={styles.classCard}>
              {/* Time Column */}
              <View style={styles.timeCol}>
                <Text style={styles.timeText}>{c.startTime}</Text>
                <Text style={styles.timeText}>{c.endTime}</Text>
              </View>
              
              <View style={styles.divider} />

              {/* Details Column */}
              <View style={styles.detailsCol}>
                <Text style={styles.subjectTitle}>{c.subject}</Text>
                <Text style={styles.profName}>{c.professor}</Text>
              </View>

              {/* Room Badge */}
              <View style={styles.roomBadge}>
                <Text style={styles.roomText}>{c.room}</Text>
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  daySelectorRow: { flexDirection: 'row', justifyContent: 'space-evenly', backgroundColor: '#fff', paddingVertical: 12, elevation: 2 },
  dayChip: { paddingVertical: 8, paddingHorizontal: 16, borderRadius: 20 },
  dayChipActive: { backgroundColor: '#1a1a2e' },
  dayText: { fontSize: 14, color: '#666', fontWeight: 'bold' },
  dayTextActive: { color: '#fff' },
  emptyState: { padding: 32, alignItems: 'center' },
  emptyText: { fontSize: 16, color: '#888' },
  classCard: { flexDirection: 'row', backgroundColor: '#fff', marginHorizontal: 16, marginTop: 16, padding: 16, borderRadius: 12, elevation: 1 },
  timeCol: { justifyContent: 'center', alignItems: 'center', width: 60 },
  timeText: { fontSize: 14, color: '#555', fontWeight: 'bold' },
  divider: { width: 1, backgroundColor: '#eee', marginHorizontal: 12 },
  detailsCol: { flex: 1, justifyContent: 'center' },
  subjectTitle: { fontSize: 16, fontWeight: 'bold', color: '#1a1a2e', marginBottom: 4 },
  profName: { fontSize: 14, color: '#666' },
  roomBadge: { backgroundColor: '#e9ecef', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8, justifyContent: 'center' },
  roomText: { fontSize: 12, fontWeight: 'bold', color: '#333' },
});
