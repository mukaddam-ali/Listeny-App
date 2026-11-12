/// Spacing/radius tokens ported from Nocturne's compact (0.7×) scale.
class NocturneSpace {
  NocturneSpace._();
  static const s1 = 2.8;
  static const s2 = 5.6;
  static const s3 = 8.4;
  static const s4 = 11.2;
  static const s6 = 16.8;
  static const s8 = 22.4;
}

class NocturneRadius {
  NocturneRadius._();
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 14.0;
  // For large card-style containers (e.g. Settings section groups): lg (14)
  // reads as barely-rounded/near-square at that size on an actual phone
  // screen, even though it's technically curved — this is large enough to
  // register as rounded without breaking the compact aesthetic.
  static const xl = 20.0;
}
