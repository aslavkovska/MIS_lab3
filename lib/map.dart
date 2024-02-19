import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'google_maps.dart';
import 'FINKI_location.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Map'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(41.9981, 21.4254),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'mis',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  FINKI.latitude,
                  FINKI.longitude,
                ),
                width: 100,
                height: 100,
                child: GestureDetector(
                  onTap: () {
                    // Show the alert dialog here
                    _showAlertDialog();
                  },
                  child: const Icon(Icons.pin_drop),
                ),
              )
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to show the alert dialog
  Future<void> _showAlertDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open Google Maps?'),
          content: const Text('Do you want to open Google Maps for routing?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                GoogleMaps.openGoogleMaps(
                    FINKI.latitude,
                    FINKI
                        .longitude);
                Navigator.of(context).pop();
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }
}