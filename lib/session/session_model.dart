import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String sesId;
  final String clsId;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final double geoLat;
  final double geoLng;
  final double geoRadiusM;
  final String locationName;

  SessionModel({
    required this.sesId,
    required this.clsId,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.geoLat,
    required this.geoLng,
    required this.geoRadiusM,
    required this.locationName,
  });

  bool isCurrent({DateTime? now}) {
    final n = now ?? DateTime.now();
    return !n.isBefore(startTime) && !n.isAfter(endTime);
  }

  bool isUpcoming({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.isBefore(startTime);
  }

  bool isPast({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.isAfter(endTime);
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final timeSlot = (data['time_slot'] as Map<String, dynamic>?) ?? {};
    final geofence = (data['geofence'] as Map<String, dynamic>?) ?? {};

    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return SessionModel(
      sesId: doc.id,
      clsId: data['cls_id'] ?? '',
      createdAt: toDate(data['timestamp']),
      startTime: toDate(timeSlot['start']),
      endTime: toDate(timeSlot['end']),
      geoLat: toDouble(geofence['lat']),
      geoLng: toDouble(geofence['lng']),
      geoRadiusM: toDouble(geofence['radius_m']),
      locationName: data['location_name'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cls_id': clsId,
      'timestamp': Timestamp.fromDate(createdAt),
      'time_slot': {
        'start': Timestamp.fromDate(startTime),
        'end': Timestamp.fromDate(endTime),
      },
      'geofence': {
        'lat': geoLat,
        'lng': geoLng,
        'radius_m': geoRadiusM,
      },
      'location_name': locationName,
    };
  }
}