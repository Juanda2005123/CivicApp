/// A geographic point. The domain's own type, so no location SDK leaks in.
class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});
}
