import 'package:flutter/material.dart';

class Event {
  final String id;
  final String name;
  final String date;
  final String time;
  final String location;
  final String description;
  final String category;
  final IconData icon;

  const Event({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.category,
    required this.icon,
  });
}
