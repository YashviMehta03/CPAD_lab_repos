import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { mockProfessors } from '../data/mockData';

export default function ProfessorsScreen() {
  return (
    <ScrollView style={styles.container}>
      {mockProfessors.map(prof => (
        <View key={prof.id} style={styles.card}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{prof.name.charAt(0)}</Text>
          </View>
          <View style={styles.info}>
            <Text style={styles.name}>{prof.name}</Text>
            <Text style={styles.dept}>{prof.department}</Text>
            <Text style={styles.details}>📍 {prof.room}  |  ✉️ {prof.email}</Text>
          </View>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5', padding: 16 },
  card: { flexDirection: 'row', backgroundColor: '#fff', padding: 16, borderRadius: 12, marginBottom: 12, alignItems: 'center', elevation: 1 },
  avatar: { width: 50, height: 50, borderRadius: 25, backgroundColor: '#1a1a2e', justifyContent: 'center', alignItems: 'center', marginRight: 16 },
  avatarText: { color: '#fff', fontSize: 20, fontWeight: 'bold' },
  info: { flex: 1 },
  name: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  dept: { fontSize: 14, color: '#666', marginTop: 2 },
  details: { fontSize: 12, color: '#888', marginTop: 6 },
});
