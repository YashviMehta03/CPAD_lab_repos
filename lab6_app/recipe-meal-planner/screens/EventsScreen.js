import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { mockEvents } from '../data/mockData';

export default function EventsScreen() {
  return (
    <ScrollView style={styles.container}>
      {mockEvents.map(event => (
        <View key={event.id} style={styles.card}>
          <Text style={styles.categoryBadge}>{event.category}</Text>
          <Text style={styles.title}>{event.title}</Text>
          <Text style={styles.detail}>📅 {event.date}</Text>
          <Text style={styles.detail}>📍 {event.location}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5', padding: 16 },
  card: { backgroundColor: '#fff', padding: 16, borderRadius: 12, marginBottom: 16, elevation: 2, position: 'relative' },
  categoryBadge: { position: 'absolute', top: 16, right: 16, backgroundColor: '#e9f5ff', color: '#007bff', paddingHorizontal: 8, paddingVertical: 4, borderRadius: 6, fontSize: 12, fontWeight: 'bold', overflow: 'hidden' },
  title: { fontSize: 18, fontWeight: 'bold', color: '#1a1a2e', marginBottom: 12, paddingRight: 60 },
  detail: { fontSize: 14, color: '#666', marginBottom: 4 },
});
