import '../core/utils/date_formatter.dart';

class AbsenModel {
  final int id;
  final int? userId;
  final String? checkIn;
  final String? checkInLocation;
  final String? checkInAddress;
  final double? checkInLat;
  final double? checkInLng;
  final String? checkOut;
  final String? checkOutLocation;
  final String? checkOutAddress;
  final double? checkOutLat;
  final double? checkOutLng;
  final String status; // 'masuk' or 'izin'
  final String? alasanIzin;
  final String? createdAt;
  final String? updatedAt;

  AbsenModel({
    required this.id,
    this.userId,
    this.checkIn,
    this.checkInLocation,
    this.checkInAddress,
    this.checkInLat,
    this.checkInLng,
    this.checkOut,
    this.checkOutLocation,
    this.checkOutAddress,
    this.checkOutLat,
    this.checkOutLng,
    required this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory AbsenModel.fromJson(Map<String, dynamic> json) {
    // If lat/lng not directly present, try parsing from check_in_location "lat, lng"
    double? parsedCheckInLat = _parseDouble(json['check_in_lat']);
    double? parsedCheckInLng = _parseDouble(json['check_in_lng']);

    if ((parsedCheckInLat == null || parsedCheckInLng == null) &&
        json['check_in_location'] != null) {
      final parts = json['check_in_location'].toString().split(',');
      if (parts.length == 2) {
        parsedCheckInLat ??= double.tryParse(parts[0].trim());
        parsedCheckInLng ??= double.tryParse(parts[1].trim());
      }
    }

    double? parsedCheckOutLat = _parseDouble(json['check_out_lat']);
    double? parsedCheckOutLng = _parseDouble(json['check_out_lng']);
    if ((parsedCheckOutLat == null || parsedCheckOutLng == null) &&
        json['check_out_location'] != null) {
      final parts = json['check_out_location'].toString().split(',');
      if (parts.length == 2) {
        parsedCheckOutLat ??= double.tryParse(parts[0].trim());
        parsedCheckOutLng ??= double.tryParse(parts[1].trim());
      }
    }

    return AbsenModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
      checkIn: json['check_in']?.toString(),
      checkInLocation: json['check_in_location']?.toString(),
      checkInAddress: json['check_in_address']?.toString(),
      checkInLat: parsedCheckInLat,
      checkInLng: parsedCheckInLng,
      checkOut: json['check_out']?.toString(),
      checkOutLocation: json['check_out_location']?.toString(),
      checkOutAddress: json['check_out_address']?.toString(),
      checkOutLat: parsedCheckOutLat,
      checkOutLng: parsedCheckOutLng,
      status: json['status']?.toString() ?? 'masuk',
      alasanIzin: json['alasan_izin']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in': checkIn,
      'check_in_location': checkInLocation,
      'check_in_address': checkInAddress,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out': checkOut,
      'check_out_location': checkOutLocation,
      'check_out_address': checkOutAddress,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'status': status,
      'alasan_izin': alasanIzin,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isIzin => status.toLowerCase() == 'izin';
  bool get isCheckedIn => checkIn != null && checkIn!.isNotEmpty;
  bool get isCheckedOut => checkOut != null && checkOut!.isNotEmpty;

  String get statusDisplay {
    if (isIzin) return 'Izin';
    if (isCheckedOut) return 'Selesai';
    if (isCheckedIn) return 'Masuk';
    return 'Belum Absen';
  }

  DateTime? get checkInDateTime => DateFormatter.parseDateTime(checkIn);
  DateTime? get checkOutDateTime => DateFormatter.parseDateTime(checkOut);
  DateTime? get createdDateTime => DateFormatter.parseDateTime(createdAt);

  String get formattedDate {
    final dt = checkInDateTime ?? createdDateTime;
    if (dt != null) {
      return DateFormatter.formatFullDate(dt);
    }
    return '-';
  }

  String get formattedShortDate {
    final dt = checkInDateTime ?? createdDateTime;
    if (dt != null) {
      return DateFormatter.formatShortDate(dt);
    }
    return '-';
  }

  String get checkInTimeDisplay {
    final dt = checkInDateTime;
    if (dt != null) {
      return DateFormatter.formatTime(dt);
    }
    return '-';
  }

  String get checkOutTimeDisplay {
    if (isIzin) return 'Tidak Perlu (Izin)';
    final dt = checkOutDateTime;
    if (dt != null) {
      return DateFormatter.formatTime(dt);
    }
    return 'Belum Pulang';
  }

  double get displayLatitude => checkInLat ?? -6.2088;
  double get displayLongitude => checkInLng ?? 106.8456;
}
