import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EventModel {
  final String id;
  final String name;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final double price;
  final XFile? image;
  final String status;

  EventModel({
    required this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    required this.price,
    this.image,
    this.status = 'En attente',
  });
}
