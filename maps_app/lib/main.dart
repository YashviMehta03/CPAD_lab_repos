import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MapDemoApp());
}

class MapDemoApp extends StatelessWidget {
  const MapDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Demo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Initial camera position: VJTI Campus, Mumbai
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0222, 72.8561),
    zoom: 14.5,
  );

  final Set<Marker> _markers = {};
  Position? _currentPosition;

  // Predefined Points of Interest
  static const List<Map<String, dynamic>> _pois = [
    {
      'id': 'poi_matunga',
      'lat': 19.0274,
      'lng': 72.8502,
      'title': 'Matunga Station',
      'snippet': 'Central Railway station in Mumbai',
    },
    {
      'id': 'poi_five_gardens',
      'lat': 19.020171,
      'lng': 72.853732,
      'title': 'Five Gardens',
      'snippet': 'Park in Matunga East',
    },
    {
      'id': 'poi_dadar',
      'lat': 19.0178,
      'lng': 72.8478,
      'title': 'Dadar Station',
      'snippet': 'Major railway junction in Mumbai',
    },
  ];

  @override
  void initState() {
    super.initState();
    _addPoiMarkers();
    _setupLocation();
  }

  /// Adds predefined POI markers to the map.
  void _addPoiMarkers() {
    final poiMarkers = _pois.map((poi) {
      return Marker(
        markerId: MarkerId(poi['id'] as String),
        position: LatLng(poi['lat'] as double, poi['lng'] as double),
        infoWindow: InfoWindow(
          title: poi['title'] as String,
          snippet: poi['snippet'] as String,
        ),
      );
    }).toSet();

    setState(() {
      _markers.addAll(poiMarkers);
    });
  }

  /// Requests location permission and fetches the current position.
  Future<void> _setupLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are disabled.');
      return;
    }

    // Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Location permission permanently denied.');
      return;
    }

    // Try to get current position with a timeout
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fallback to last known position (common on emulators)
      _currentPosition = await Geolocator.getLastKnownPosition();
    }

    if (_currentPosition != null) {
      _updateCameraAndMarkers();
    } else {
      _showMessage('Could not determine current location.');
    }
  }

  /// Moves the camera to current position and adds a "You are here" marker.
  Future<void> _updateCameraAndMarkers() async {
    if (_currentPosition == null) return;

    final controller = await _controller.future;
    final target = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: target,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Current Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    });
  }

  /// Re-centers the map on the user's current location.
  Future<void> _recenterMap() async {
    if (_currentPosition == null) {
      _showMessage('Location unavailable. Cannot re-center.');
      return;
    }

    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Demo App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterMap,
        tooltip: 'Re-center Map',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
