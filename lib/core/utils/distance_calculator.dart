import 'dart:math';

class DistanceCalculator {
  static double calculate(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double earthRadius = 6371000;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double radLat1 = _toRadians(lat1);
    double radLat2 = _toRadians(lat2);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radLat1) * cos(radLat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    return distance;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  static bool isWithinRange(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      double threshold,
      ) {
    double distance = calculate(lat1, lon1, lat2, lon2);
    return distance <= threshold;
  }
}