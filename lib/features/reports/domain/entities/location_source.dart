/// Where the point of a report comes from (HU-28). The GPS and a point
/// confirmed on the map are the citizen's own decision and are never replaced
/// by the typed address; an address or the city center is only an estimate.
enum LocationSource {
  /// Read from the device GPS.
  gps,

  /// Confirmed on the Step 1 map (HU-27).
  mapPoint,

  /// Estimated from the typed address (HU-28).
  address,

  /// The center of the city: the starting point, or the fallback when the
  /// address could not be located (HU-28).
  cityCenter;

  /// The citizen set this point, so the address must not move it.
  bool get isChosenByCitizen => this == gps || this == mapPoint;
}
