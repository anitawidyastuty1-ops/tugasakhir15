import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDataResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isMockOrFallback;

  LocationDataResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isMockOrFallback = false,
  });
}

class LocationService {
  // Default coordinates (PPKD Jakarta / Jakarta Pusat)
  static const double defaultLat = -6.2088;
  static const double defaultLng = 106.8456;
  static const String defaultAddress = 'PPKD Jakarta, DKI Jakarta';

  static Future<LocationDataResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return LocationDataResult(
          latitude: defaultLat,
          longitude: defaultLng,
          address: '$defaultAddress (GPS Dinonaktifkan)',
          isMockOrFallback: true,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationDataResult(
            latitude: defaultLat,
            longitude: defaultLng,
            address: '$defaultAddress (Izin Ditolak)',
            isMockOrFallback: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationDataResult(
          latitude: defaultLat,
          longitude: defaultLng,
          address: '$defaultAddress (Izin Ditolak Permanen)',
          isMockOrFallback: true,
        );
      }

      // Permissions are granted, fetch position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationDataResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        isMockOrFallback: false,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return LocationDataResult(
        latitude: defaultLat,
        longitude: defaultLng,
        address: defaultAddress,
        isMockOrFallback: true,
      );
    }
  }

  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
    }

    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)} (Jakarta)';
  }
}
