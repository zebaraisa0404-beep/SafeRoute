import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class _Incident {
  final String id;
  final String title;
  final String type;
  final String severity;
  final LatLng location;

  const _Incident({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.location,
  });
}

class _RoadRoute {
  final List<LatLng> points;
  final double distanceKm;
  final double minutes;
  final int hazardCount;

  const _RoadRoute({
    required this.points,
    required this.distanceKm,
    required this.minutes,
    required this.hazardCount,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final Distance distance = const Distance();

  StreamSubscription<Position>? gpsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? incidentSubscription;

  LatLng? myLocation;
  LatLng? destination;
  _Incident? selectedIncident;

  bool mapReady = false;
  bool loading = false;
  bool loadingIncidents = true;
  String info = 'Getting current location...';
  String? incidentError;

  List<_Incident> incidents = [];
  List<_RoadRoute> routes = [];
  int selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    listenToIncidents();
    startLocation();
  }

  // Changes in Firestore arrive on this stream without reloading the page.
  void listenToIncidents() {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        loadingIncidents = false;
        incidentError = 'Please log in to view incident reports.';
      });
      return;
    }

    incidentSubscription = FirebaseFirestore.instance
        .collection('incidents')
        .snapshots()
        .listen((snapshot) {
      final updated = <_Incident>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'Resolved') continue;
        final lat = data['latitude'];
        final lng = data['longitude'];
        if (lat is! num || lng is! num) continue;
        final latitude = lat.toDouble();
        final longitude = lng.toDouble();
        if (!latitude.isFinite || !longitude.isFinite ||
            latitude < -90 || latitude > 90 ||
            longitude < -180 || longitude > 180) {
          continue;
        }
        final type = data['category']?.toString() ?? 'Incident';
        final locationName = data['location']?.toString() ?? '';
        updated.add(_Incident(
          id: doc.id,
          title: '$type${locationName.isEmpty ? '' : ' - $locationName'}',
          type: type,
          severity: data['severity']?.toString() ?? 'Unknown',
          location: LatLng(latitude, longitude),
        ));
      }

      if (!mounted) return;
      final oldIds = incidents.map((e) => '${e.id}:${e.location.latitude}:${e.location.longitude}').join('|');
      final newIds = updated.map((e) => '${e.id}:${e.location.latitude}:${e.location.longitude}').join('|');
      setState(() {
        incidents = updated;
        loadingIncidents = false;
        incidentError = null;
        if (oldIds != newIds && routes.isNotEmpty) {
          routes = [];
          selectedRouteIndex = 0;
          info = 'Incident data updated. Find routes again.';
        }
        if (selectedIncident != null &&
            !updated.any((e) => e.id == selectedIncident!.id)) {
          selectedIncident = null;
        }
      });
    }, onError: (Object error) {
      if (!mounted) return;
      setState(() {
        loadingIncidents = false;
        incidentError = 'Could not load incidents: $error';
      });
    });
  }

  Future<void> startLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => info = 'Enable device location to show your position.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => info = 'Allow location access in Chrome for GPS tracking.');
        return;
      }

      await gpsSubscription?.cancel();
      gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (!mounted) return;
        final point = LatLng(position.latitude, position.longitude);
        final first = myLocation == null;
        setState(() {
          myLocation = point;
          info = 'Live GPS tracking active';
        });
        if (first && mapReady) mapController.move(point, 14);
      }, onError: (Object error) {
        if (mounted) setState(() => info = 'GPS error: $error');
      });
    } catch (error) {
      if (mounted) setState(() => info = 'Location unavailable: $error');
    }
  }

  double metersBetween(LatLng a, LatLng b) =>
      distance.as(LengthUnit.Meter, a, b);

  bool isNearby(_Incident incident) =>
      myLocation != null && metersBetween(myLocation!, incident.location) < 1200;

  // Approximate shortest distance from an incident to a route segment (metres).
  double pointToSegment(LatLng incident, LatLng a, LatLng b) {
    const earth = 111320.0;
    final factor = math.cos(incident.latitude * math.pi / 180);
    final ax = (a.longitude - incident.longitude) * earth * factor;
    final ay = (a.latitude - incident.latitude) * earth;
    final bx = (b.longitude - incident.longitude) * earth * factor;
    final by = (b.latitude - incident.latitude) * earth;
    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return math.sqrt(ax * ax + ay * ay);
    final t = (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
    final x = ax + t * dx;
    final y = ay + t * dy;
    return math.sqrt(x * x + y * y);
  }

  int calculateHazards(List<LatLng> points) {
    if (points.isEmpty) return 0;
    var count = 0;
    for (final incident in incidents) {
      var closest = double.infinity;
      if (points.length == 1) {
        closest = metersBetween(points.first, incident.location);
      } else {
        for (var i = 0; i < points.length - 1; i++) {
          final metres = pointToSegment(
            incident.location, points[i], points[i + 1],
          );
          if (metres < closest) closest = metres;
        }
      }
      if (closest < 200) count++;
    }
    return count;
  }

  void centerOnUser() {
    if (myLocation == null) {
      if (mounted) setState(() => info = 'Waiting for GPS location...');
      return;
    }
    if (mapReady) mapController.move(myLocation!, 15);
  }

  void chooseDestination(LatLng point) {
    setState(() {
      destination = point;
      selectedIncident = null;
      routes = [];
      selectedRouteIndex = 0;
      info = 'Destination selected. Tap Find Alternative Routes.';
    });
  }

  void useDemoDestination() {
    if (myLocation == null) {
      setState(() => info = 'GPS required before selecting a demo destination.');
      return;
    }
    final point = LatLng(
      myLocation!.latitude + 0.012,
      myLocation!.longitude + 0.012,
    );
    chooseDestination(point);
    if (mapReady) mapController.move(point, 13);
  }

  Future<void> findRoutes() async {
    if (loading) return;
    if (myLocation == null || destination == null) {
      setState(() => info = 'Enable GPS and tap the map to choose a destination.');
      return;
    }
    setState(() {
      loading = true;
      routes = [];
      info = 'Searching for available road routes...';
    });

    final start = myLocation!;
    final end = destination!;
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?alternatives=true&overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Routing HTTP ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        throw Exception('Routing response: ${data['code']}');
      }
      final raw = data['routes'] as List? ?? [];
      final found = <_RoadRoute>[];

      for (final item in raw) {
        final route = item as Map<String, dynamic>;
        final geometry = route['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List;
        final points = coords.map<LatLng>((coordinate) {
          return LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          );
        }).toList();
        if (points.isEmpty) continue;
        found.add(_RoadRoute(
          points: points,
          distanceKm: (route['distance'] as num).toDouble() / 1000,
          minutes: (route['duration'] as num).toDouble() / 60,
          hazardCount: calculateHazards(points),
        ));
      }
      found.sort((a, b) {
        final byHazards = a.hazardCount.compareTo(b.hazardCount);
        return byHazards != 0
            ? byHazards
            : a.distanceKm.compareTo(b.distanceKm);
      });

      if (!mounted) return;
      setState(() {
        routes = found;
        selectedRouteIndex = 0;
        info = found.isEmpty
            ? 'No road route found.'
            : found.length == 1
                ? 'One route found. No alternative was returned.'
                : '${found.length} routes found. Lowest reported-incident proximity ranked first.';
      });
      if (found.isNotEmpty && mapReady) {
        mapController.fitCamera(CameraFit.coordinates(
          coordinates: [for (final route in found) ...route.points],
          padding: const EdgeInsets.all(45),
        ));
      }
    } catch (error) {
      if (mounted) setState(() => info = 'Route error: $error');
      debugPrint('SafeRoute routing error: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    gpsSubscription?.cancel();
    incidentSubscription?.cancel();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearby = incidents.where(isNearby).toList();
    final markers = <Marker>[
      if (myLocation != null)
        Marker(
          point: myLocation!, width: 48, height: 48,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
        ),
      for (final incident in incidents)
        Marker(
          point: incident.location, width: 50, height: 50,
          child: GestureDetector(
            onTap: () => setState(() => selectedIncident = incident),
            child: Icon(
              incident.type == 'Fire'
                  ? Icons.local_fire_department
                  : Icons.warning_rounded,
              size: 42, color: Colors.red,
            ),
          ),
        ),
      if (destination != null)
        Marker(
          point: destination!, width: 50, height: 50,
          child: const Icon(Icons.flag, color: Colors.green, size: 42),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeRoute Live Map'),
        backgroundColor: const Color(0xFFDCEBFA),
        actions: [
          IconButton(
            tooltip: 'My Location',
            onPressed: centerOnUser,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Text(info, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
                if (loadingIncidents) const LinearProgressIndicator(),
                if (incidentError != null)
                  Text(incidentError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                Text('${incidents.length} active geotagged report(s) on map',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          if (nearby.isNotEmpty)
            Material(
              color: Colors.orange.shade100,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.notifications_active, color: Colors.red),
                title: Text('${nearby.length} reported incident(s) within 1.2 km'),
                subtitle: const Text(
                  'Community reports are unverified; not an official emergency alert.',
                ),
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(23.8103, 90.4125),
                initialZoom: 12,
                onMapReady: () {
                  mapReady = true;
                  if (myLocation != null) mapController.move(myLocation!, 14);
                },
                onTap: (_, point) => chooseDestination(point),
                onLongPress: (_, point) => chooseDestination(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.saferoute.studentdemo',
                ),
                PolylineLayer(polylines: [
                  for (var i = 0; i < routes.length; i++)
                    Polyline(
                      points: routes[i].points,
                      strokeWidth: i == selectedRouteIndex ? 6 : 3,
                      color: i == selectedRouteIndex
                          ? Colors.green : Colors.orange,
                    ),
                ]),
                MarkerLayer(markers: markers),
                RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ]),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 260),
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedIncident != null)
                    Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(selectedIncident!.title),
                        subtitle: Text(
                          'Category: ${selectedIncident!.type} • '
                          'Severity: ${selectedIncident!.severity}\n'
                          'Community-submitted report; not independently verified.',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => selectedIncident = null),
                        ),
                      ),
                    ),
                  Text(
                    destination == null
                        ? 'Tap a road on the map to choose destination'
                        : 'Destination selected ✓',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: useDemoDestination,
                    icon: const Icon(Icons.flag),
                    label: const Text('Use Demo Destination'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : findRoutes,
                      icon: const Icon(Icons.alt_route),
                      label: Text(loading
                          ? 'Finding Routes...'
                          : 'Find Alternative Routes'),
                    ),
                  ),
                  for (var i = 0; i < routes.length; i++)
                    Card(
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          i == selectedRouteIndex
                              ? Icons.check_circle : Icons.alt_route,
                          color: i == selectedRouteIndex
                              ? Colors.green : Colors.orange,
                        ),
                        title: Text(
                          'Route ${i + 1} - '
                          '${routes[i].distanceKm.toStringAsFixed(1)} km',
                        ),
                        subtitle: Text(
                          '${routes[i].minutes.toStringAsFixed(0)} min • '
                          '${routes[i].hazardCount} nearby reported incident(s)',
                        ),
                        selected: selectedRouteIndex == i,
                        onTap: () => setState(() => selectedRouteIndex = i),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Routes are ranked by proximity to community reports only. '
                    'Reports may be inaccurate or outdated. '
                    'No route is guaranteed safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
