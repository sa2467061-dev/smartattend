import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMapWidget extends StatelessWidget {
  final LatLng center;
  final double radius;
  final Function(LatLng)? onTap;

  const CustomMapWidget({
    super.key,
    required this.center,
    this.radius = 50,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 17,
        onTap: (_, point) => onTap?.call(LatLng(point.latitude, point.longitude)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // Required by OSM's tile usage policy — identifies your app to the server.
          userAgentPackageName: 'com.example.smartattend',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radius,
              useRadiusInMeter: true,
              color: Colors.blue.withAlpha(50),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}