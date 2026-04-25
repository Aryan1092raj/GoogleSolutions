import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/dashboard_theme.dart';

class IncidentMapWidget extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String roomNumber;
  final String severity;

  const IncidentMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.roomNumber,
    required this.severity,
  });

  @override
  State<IncidentMapWidget> createState() => _IncidentMapWidgetState();
}

class _IncidentMapWidgetState extends State<IncidentMapWidget> {
  bool get _hasCoordinates => widget.lat != null && widget.lng != null;

  LatLng get _position => LatLng(widget.lat!, widget.lng!);

  @override
  Widget build(BuildContext context) {
    if (!_hasCoordinates) {
      return Container(
        decoration: BoxDecoration(
          color: kDashSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kDashBorder),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, color: kDashTextMut, size: 28),
              SizedBox(height: 8),
              Text('No GPS data',
                  style: TextStyle(color: kDashTextMut, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _position,
            zoom: 17,
          ),
          onMapCreated: (c) {},
          markers: {
            Marker(
              markerId: const MarkerId('incident'),
              position: _position,
              infoWindow: InfoWindow(
                title: 'Room ${widget.roomNumber}',
                snippet: widget.severity,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                widget.severity == 'CRITICAL' || widget.severity == 'HIGH'
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange,
              ),
            ),
          },
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        // Severity overlay badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kDashSurface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: kDashBorder),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on, size: 12, color: Color(0xFFFF453A)),
              SizedBox(width: 5),
              Text('LIVE LOCATION',
                  style: TextStyle(
                      color: kDashText, fontSize: 10, letterSpacing: 1)),
            ]),
          ),
        ),
      ]),
    );
  }
}
