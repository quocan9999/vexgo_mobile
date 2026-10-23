import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Geometry from VexGo Web one-way-booking.tsx ChairIcon/SteeringWheelIcon.
/// Only the presentation is shared; seat IDs and positions remain API data.
class SeatVector extends StatelessWidget {
  final Color fill;
  final Color stroke;
  const SeatVector({super.key, required this.fill, required this.stroke});

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2)}';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 48">'
    '<g fill="${_hex(fill)}" stroke="${_hex(stroke)}" stroke-width="2.5">'
    '<rect x="1" y="14" width="8" height="20" rx="3"/>'
    '<rect x="31" y="14" width="8" height="20" rx="3"/>'
    '<rect x="9" y="34" width="22" height="12" rx="3"/>'
    '<rect x="7" y="2" width="26" height="38" rx="5"/>'
    '</g></svg>',
    width: 40,
    height: 48,
    excludeFromSemantics: true,
  );
}

class SteeringWheelVector extends StatelessWidget {
  const SteeringWheelVector({super.key});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
    'fill="none" stroke="#64748B" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/>'
    '<path d="M12 2v7M4.93 19.07l4.95-4.95M19.07 19.07l-4.95-4.95"/>'
    '</svg>',
    width: 24,
    height: 24,
    excludeFromSemantics: true,
  );
}
