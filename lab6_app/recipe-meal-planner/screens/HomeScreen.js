import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { mockTimetable, mockEvents } from '../data/mockData';

export default function HomeScreen({ navigation }) {
  const currentDate = new Date().toDateString();
  
  // Get current day logic for 'Today's Classes' (fallback to MON if weekend for demo purposes)
  const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  let currentDayName = days[new Date().getDay()];
  if (currentDayName === 'SUN' || currentDayName === 'SAT') {
    currentDayName = 'MON'; // Fallback for the weekend so it doesn't look empty
  }
  const todaysClasses = mockTimetable[currentDayName] || [];

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header Section */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Hello, Student! 👋</Text>
          <Text style={styles.title}>Campus Companion</Text>
          <Text style={styles.date}>{currentDate}</Text>
        </View>
      </View>

      {/* Dashboard Grid */}
      <Text style={styles.sectionTitle}>Dashboard</Text>
      <View style={styles.grid}>
        <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('Timetable')}>
          <Text style={styles.cardIcon}>📅</Text>
          <Text style={styles.cardTitle}>Timetable</Text>
          <Text style={styles.cardDesc}>View your schedule</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('Professors')}>
          <Text style={styles.cardIcon}>👨‍🏫</Text>
          <Text style={styles.cardTitle}>Professors</Text>
          <Text style={styles.cardDesc}>Faculty directory</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('Events')}>
          <Text style={styles.cardIcon}>🎉</Text>
          <Text style={styles.cardTitle}>Events</Text>
          <Text style={styles.cardDesc}>Campus events</Text>
        </TouchableOpacity>

        <View style={styles.cardDisabled}>
          <Text style={styles.badge}>Soon</Text>
          <Text style={styles.cardIcon}>🏢</Text>
          <Text style={styles.cardTitle}>Lost & Found</Text>
          <Text style={styles.cardDesc}>Report items</Text>
        </View>
      </View>

      {/* Today's Classes Section */}
      <View style={styles.sectionHeaderRow}>
        <Text style={styles.sectionTitle}>Today's Classes ({currentDayName})</Text>
        <TouchableOpacity onPress={() => navigation.navigate('Timetable')}>
          <Text style={styles.seeAllText}>See all</Text>
        </TouchableOpacity>
      </View>

      {todaysClasses.length === 0 ? (
        <View style={styles.emptyCard}>
          <Text style={styles.emptyText}>No classes scheduled for today! 🎉</Text>
        </View>
      ) : (
        todaysClasses.slice(0, 2).map((c, index) => (
          <View key={index} style={styles.classCard}>
            <View style={styles.timeCol}>
              <Text style={styles.timeText}>{c.startTime}</Text>
              <Text style={styles.timeText}>{c.endTime}</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.detailsCol}>
              <Text style={styles.subjectTitle}>{c.subject}</Text>
              <Text style={styles.profName}>{c.professor}</Text>
            </View>
            <View style={styles.roomBadge}>
              <Text style={styles.roomText}>{c.room}</Text>
            </View>
          </View>
        ))
      )}

      {/* Upcoming Event Section */}
      <Text style={[styles.sectionTitle, { marginTop: 20 }]}>Upcoming Event</Text>
      <TouchableOpacity 
        style={styles.eventCard} 
        onPress={() => navigation.navigate('Events')}
      >
        <Text style={styles.eventCategoryBadge}>{mockEvents[0].category}</Text>
        <Text style={styles.eventTitle}>{mockEvents[0].title}</Text>
        <Text style={styles.eventDetail}>📅 {mockEvents[0].date}</Text>
        <Text style={styles.eventDetail}>📍 {mockEvents[0].location}</Text>
      </TouchableOpacity>

      {/* Bottom Padding */}
      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5', padding: 16 },
  header: { marginBottom: 24, marginTop: 10 },
  greeting: { fontSize: 16, color: '#666', fontWeight: '500' },
  title: { fontSize: 28, fontWeight: '800', color: '#1a1a2e', marginTop: 4 },
  date: { fontSize: 14, color: '#888', marginTop: 4, fontWeight: '500' },
  sectionHeaderRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 12, marginBottom: 16 },
  sectionTitle: { fontSize: 20, fontWeight: 'bold', color: '#1a1a2e', marginBottom: 16 },
  seeAllText: { fontSize: 14, color: '#007bff', fontWeight: 'bold' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' },
  card: { width: '48%', backgroundColor: '#fff', padding: 16, borderRadius: 16, marginBottom: 16, elevation: 2, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 6, shadowOffset: { width: 0, height: 3 } },
  cardDisabled: { width: '48%', backgroundColor: '#eaeaea', padding: 16, borderRadius: 16, marginBottom: 16, position: 'relative' },
  cardIcon: { fontSize: 32, marginBottom: 12 },
  cardTitle: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  cardDesc: { fontSize: 12, color: '#777', marginTop: 4 },
  badge: { position: 'absolute', top: 12, right: 12, backgroundColor: '#ff4757', color: '#fff', fontSize: 10, paddingHorizontal: 6, paddingVertical: 2, borderRadius: 8, fontWeight: 'bold', overflow: 'hidden' },
  emptyCard: { backgroundColor: '#fff', padding: 24, borderRadius: 16, alignItems: 'center', elevation: 1 },
  emptyText: { color: '#888', fontSize: 14, fontStyle: 'italic' },
  classCard: { flexDirection: 'row', backgroundColor: '#fff', padding: 16, borderRadius: 16, marginBottom: 12, elevation: 1, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, shadowOffset: { width: 0, height: 2 } },
  timeCol: { justifyContent: 'center', alignItems: 'center', width: 60 },
  timeText: { fontSize: 14, color: '#555', fontWeight: 'bold' },
  divider: { width: 1, backgroundColor: '#eee', marginHorizontal: 12 },
  detailsCol: { flex: 1, justifyContent: 'center' },
  subjectTitle: { fontSize: 16, fontWeight: 'bold', color: '#1a1a2e', marginBottom: 4 },
  profName: { fontSize: 14, color: '#666' },
  roomBadge: { backgroundColor: '#e9ecef', paddingHorizontal: 10, paddingVertical: 6, borderRadius: 8, justifyContent: 'center' },
  roomText: { fontSize: 12, fontWeight: 'bold', color: '#333' },
  eventCard: { backgroundColor: '#fff', padding: 20, borderRadius: 16, elevation: 2, position: 'relative', shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 6, shadowOffset: { width: 0, height: 3 } },
  eventCategoryBadge: { position: 'absolute', top: 16, right: 16, backgroundColor: '#e9f5ff', color: '#007bff', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8, fontSize: 12, fontWeight: 'bold', overflow: 'hidden' },
  eventTitle: { fontSize: 18, fontWeight: 'bold', color: '#1a1a2e', marginBottom: 12, paddingRight: 70 },
  eventDetail: { fontSize: 14, color: '#666', marginBottom: 6 },
});
