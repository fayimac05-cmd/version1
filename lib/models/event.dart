import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final double price;
  final XFile? image;
  final String? imageUrl;
  final String status;
  final int inscrits;
  final int capacite;

  EventModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.location,
    required this.date,
    required this.time,
    required this.price,
    this.image,
    this.imageUrl,
    this.status = 'En attente',
    this.inscrits = 0,
    this.capacite = 0,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final dateDebut =
        DateTime.tryParse(json['date_debut'] ?? '') ?? DateTime.now();
    return EventModel(
      id: json['id'].toString(),
      name: json['titre'] ?? '',
      description: json['description'] ?? '',
      location: json['lieu'] ?? '',
      date: dateDebut,
      time: TimeOfDay(hour: dateDebut.hour, minute: dateDebut.minute),
      price: double.tryParse(json['prix']?.toString() ?? '') ?? 0,
      imageUrl: json['affiche_url'],
      status: statutLabel(json['statut']),
      inscrits: json['inscrits'] is int
          ? json['inscrits']
          : int.tryParse(json['inscrits']?.toString() ?? '') ?? 0,
      capacite: json['capacite'] is int
          ? json['capacite']
          : int.tryParse(json['capacite']?.toString() ?? '') ?? 0,
    );
  }

  static String statutLabel(String? statut) {
    switch (statut) {
      case 'approuve':
        return 'Approuvé';
      case 'annule':
        return 'Annulé';
      default:
        return 'En attente';
    }
  }
}
