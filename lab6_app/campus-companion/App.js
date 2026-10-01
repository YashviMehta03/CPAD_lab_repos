import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import HomeScreen from './screens/HomeScreen';
import TimetableScreen from './screens/TimetableScreen';
import ProfessorsScreen from './screens/ProfessorsScreen';
import EventsScreen from './screens/EventsScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: { backgroundColor: '#1a1a2e' },
          headerTintColor: '#fff',
          headerTitleStyle: { fontWeight: 'bold' },
        }}
      >
        <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Dashboard' }} />
        <Stack.Screen name="Timetable" component={TimetableScreen} options={{ title: 'Weekly Timetable' }} />
        <Stack.Screen name="Professors" component={ProfessorsScreen} options={{ title: 'Faculty Directory' }} />
        <Stack.Screen name="Events" component={EventsScreen} options={{ title: 'Campus Events' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
