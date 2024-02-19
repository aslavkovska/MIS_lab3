import 'package:url_launcher/url_launcher.dart';

class GoogleMaps {
  GoogleMaps();

  static void openGoogleMaps(double latitude, double longitude) async {
    final double Latitude = latitude;
    final double Longitude = longitude;

    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$Latitude,$Longitude';
    final Uri uri = Uri.parse(googleMapsUrl);

    await launchUrl(uri);
  }
}