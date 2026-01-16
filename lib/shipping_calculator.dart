import 'dart:math' show cos, sqrt, asin;

class ShippingCalculator {
  /// Calculates the distance between two coordinates in kilometers using the Haversine formula.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295; // Pi / 180
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Calculates shipping cost based on distance.
  /// Rule: 1000 IDR per 1 km, with a minimum of 1000 IDR.
  static int calculateShippingCost(double distanceKm) {
    const int pricePerKm = 1000;
    const int minPrice = 1000;

    // Calculate cost and round up
    int cost = (distanceKm * pricePerKm).ceil();

    return cost < minPrice ? minPrice : cost;
  }
}
