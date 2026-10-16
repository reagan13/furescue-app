import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/tokens.dart';

/// OpenStreetMap pin, matching the web Leaflet map.
///
/// Without a pin the map sits on Mati City so the person can see the area
/// before GPS returns.
class PinMap extends StatelessWidget {
  const PinMap({
    super.key,
    this.latitude,
    this.longitude,
    this.height = 180,
  });

  final double? latitude;
  final double? longitude;
  final double height;

  static const mati = LatLng(6.95, 126.20);

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    final center = hasPin ? LatLng(latitude!, longitude!) : mati;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          key: ValueKey('${latitude ?? 'mati'},${longitude ?? 'mati'}'),
          options: MapOptions(
            initialCenter: center,
            initialZoom: hasPin ? 16 : 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.furescue.app',
            ),
            if (hasPin)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_pin,
                      color: context.tokens.jungle,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
