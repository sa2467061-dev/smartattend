import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single class session document from the `session` collection.
///
/// Firestore shape:
/// session (
///   ses_id, cls_id, timestamp, time_slot { start, end },
///   geofence { lat, lng, radius_m }, qr_code, qr_expire
/// )
class SessionModel {
  final String sesId; // Firestore document ID
  final String clsId; // Parent class this session belongs to
  final DateTime createdAt; // When the session doc was created (lecturer action)
  final DateTime startTime; // time_slot.start
  final DateTime endTime; // time_slot.end
  final double geoLat;
  final double geoLng;
  final double geoRadiusM; // radius in meters
  final String qrCode; // unique code embedded in the generated QR
  final DateTime qrExpire; // when the QR code stops being valid

  SessionModel({
    required this.sesId,
    required this.clsId,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.geoLat,
    required this.geoLng,
    required this.geoRadiusM,
    required this.qrCode,
    required this.qrExpire,
  });

  // --- Derived status helpers -----------------------------------------

  /// True if `now` falls within [startTime, endTime] — this is the
  /// "current session" definition agreed on: automatic by time-slot.
  bool isCurrent({DateTime? now}) {
    final n = now ?? DateTime.now();
    return !n.isBefore(startTime) && !n.isAfter(endTime);
  }

  /// True if the session hasn't started yet.
  bool isUpcoming({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.isBefore(startTime);
  }

  /// True if the session has already ended.
  bool isPast({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.isAfter(endTime);
  }

  /// True if the QR code is still valid for scanning right now.
  bool isQrValid({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.isBefore(qrExpire);
  }

  // --- Firestore (de)serialization ------------------------------------

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final timeSlot = (data['time_slot'] as Map<String, dynamic>?) ?? {};
    final geofence = (data['geofence'] as Map<String, dynamic>?) ?? {};

    DateTime _toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now(); // safe fallback, should not normally hit this
    }

    double _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return SessionModel(
      sesId: doc.id,
      clsId: data['cls_id'] ?? '',
      createdAt: _toDate(data['timestamp']),
      startTime: _toDate(timeSlot['start']),
      endTime: _toDate(timeSlot['end']),
      geoLat: _toDouble(geofence['lat']),
      geoLng: _toDouble(geofence['lng']),
      geoRadiusM: _toDouble(geofence['radius_m']),
      qrCode: data['qr_code'] ?? '',
      qrExpire: _toDate(data['qr_expire']),
    );
  }

  /// Builds the map to write to Firestore. Used by add_session.dart.
  /// `ses_id` is intentionally omitted — Firestore assigns the doc ID.
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
      'qr_code': qrCode,
      'qr_expire': Timestamp.fromDate(qrExpire),
    };
  }
}