// delivery_tracking_page.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryTrackingPage extends StatefulWidget {
  final String shipmentId;
  final Map<String, dynamic> shippingData;

  const DeliveryTrackingPage({
    super.key,
    required this.shipmentId,
    required this.shippingData,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  final MapController _mapController = MapController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ScrollController _scrollController = ScrollController();
  final _isAppBarCollapsed = ValueNotifier<bool>(false);

  Map<String, dynamic>? _deliveryData;
  String? _selectedRider;
  bool _isLoading = false;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  double _totalDistance = 0;
  double _remainingDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _setupDeliveryListener();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > (300 - 10 - kToolbarHeight);
    if (isCollapsed != _isAppBarCollapsed) {
      _isAppBarCollapsed.value =
          isCollapsed; // This will trigger rebuiding the text widget.
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _firestore.collection('shipments').doc(widget.shipmentId).get();
      setState(() {
        _deliveryData = doc.data();
        _selectedRider = _deliveryData?['riderUid'];
        print('Selected Rider: $_selectedRider');
      });
      _updateRoutePoints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading delivery data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupDeliveryListener() {
    _firestore
        .collection('shipments')
        .doc(widget.shipmentId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _deliveryData = snapshot.data();
        _updateRoutePoints();
      });
    });
  }

  Future<void> _updateRoutePoints() async {
    if (_deliveryData == null) return;

    final startLoc = _deliveryData!['shipmentFromLoc'];
    final endLoc = _deliveryData!['shipmentToLoc'];
    final intermediatePoints = List<Map<String, dynamic>>.from(
        _deliveryData!['intermediatePoints'] ?? []);

    final points = [startLoc, ...intermediatePoints, endLoc];
    List<LatLng> fullRoute = [];

    for (int i = 0; i < points.length - 1; i++) {
      final startPoint = points[i];
      final endPoint = points[i + 1];

      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/'
          '${startPoint['lon']},${startPoint['lat']};'
          '${endPoint['lon']},${endPoint['lat']}'
          '?overview=full&geometries=geojson');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            // Safe type casting of coordinates
            final coordinates =
                (data['routes'][0]['geometry']['coordinates'] as List)
                    .map((coord) {
              if (coord is List && coord.length >= 2) {
                final lon = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                return LatLng(lat, lon);
              }
              throw FormatException('Invalid coordinate format');
            }).toList();

            fullRoute.addAll(coordinates);
          }
        }
      } catch (e) {
        print('Error calculating route: $e');
        // Fallback to straight line
        fullRoute.addAll([
          LatLng(startPoint['lat'], startPoint['lon']),
          LatLng(endPoint['lat'], endPoint['lon'])
        ]);
      }
    }

    setState(() {
      _routePoints = fullRoute;
      _calculateDistances();
    });

    // Update map view
    if (fullRoute.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(fullRoute);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 75),
        ),
      );
    }
  }

  void _calculateDistances() {
    double total = 0;
    double remaining = 0;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final distance = _calculateDistance(
        _routePoints[i],
        _routePoints[i + 1],
      );
      total += distance;

      if (_currentLocation != null) {
        final currentToNextDistance = _calculateDistance(
          _currentLocation!,
          _routePoints[i + 1],
        );
        remaining = currentToNextDistance;
      }
    }

    setState(() {
      _totalDistance = total;
      _remainingDistance = remaining;
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Haversine formula implementation
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLon = _toRadians(end.longitude - start.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(start.latitude)) *
            cos(_toRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return
    RepaintBoundary(
      child: 
     Scaffold(
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            SliverAppBar.large(
              automaticallyImplyLeading: false,
              expandedHeight: 300,
              pinned: true,
              title: null,
              centerTitle: true,
              flexibleSpace: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Builder(builder: (BuildContext context) {
                    return FlexibleSpaceBar(
                      background: SizedBox(
                        height: 300,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _routePoints.isNotEmpty
                                ? _routePoints.first
                                : LatLng(0, 0),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: ['a', 'b', 'c'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  color: Colors.blue,
                                  strokeWidth: 3.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: _buildMarkers(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  ValueListenableBuilder(
                      valueListenable: _isAppBarCollapsed,
                      builder:
                          (BuildContext context, bool value, Widget? child) {
                        return IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: value ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withAlpha(0),
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(FluentIcons.arrow_left_24_regular),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IgnorePointer(
                            child: SizedBox(
                          width: 200,
                          child: FlexibleSpaceBar(
                            background: null,
                            expandedTitleScale: 1.75,
                            titlePadding: const EdgeInsets.only(bottom: 10),
                            title: Text('Delivery',
                                style: Theme.of(context).textTheme.titleLarge),
                            centerTitle: true,
                          ),
                        )),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(FluentIcons.zoom_fit_24_regular),
                          onPressed: () async {
                            if (_routePoints.isNotEmpty) {
                              final bounds =
                                  LatLngBounds.fromPoints(_routePoints);
                              _mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: bounds,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 75),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSection(),
                    if (_selectedRider != null && _selectedRider!.isNotEmpty)
                      FutureBuilder<DataSnapshot>(
                        future: _database.ref('users/$_selectedRider').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final userData = Map<String, dynamic>.from(snapshot.data!.value as Map);
                          
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Rider', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(userData['thumbProfileImage'] ?? ''),
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${userData['firstName']} ${userData['middleName']} ${userData['lastName']}',
                                              style: Theme.of(context).textTheme.titleMedium),
                                          Text(userData['number'] ?? '',
                                              style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (_deliveryData != null)
                      DeliveryStatusTimeline(
                        statuses: _deliveryData!['status'] ?? {},
                      ),
                  ],
                ),
              ),
            ),
          ]),)
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_routePoints.isNotEmpty) {
      // Start marker
      markers.add(Marker(
        point: _routePoints.first,
        child: Transform.translate(
          offset: Offset(0, -15), // Move up by half the icon height
          child: Icon(FluentIcons.location_24_filled,
              color: Colors.green, size: 30),
        ),
      ));

      // Intermediate points markers
      if (_deliveryData != null &&
          _deliveryData!['intermediatePoints'] != null) {
        final intermediatePoints = List<Map<String, dynamic>>.from(
            _deliveryData!['intermediatePoints']);

        for (var point in intermediatePoints) {
          markers.add(Marker(
            point: LatLng(point['lat'], point['lon']),
            child: Transform.translate(
              offset: Offset(0, -12.5), // Move up by half the icon height
              child: Icon(
                FluentIcons.location_24_filled,
                color: Colors.orange,
                size: 25,
              ),
            ),
          ));
        }
      }

      // End marker
      markers.add(Marker(
        point: _routePoints.last,
        child: Transform.translate(
          offset: Offset(0, -15), // Move up by half the icon height
          child:
              Icon(FluentIcons.location_24_filled, color: Colors.red, size: 30),
        ),
      ));

      // Current location marker
      if (_currentLocation != null) {
        markers.add(Marker(
          point: _currentLocation!,
          child: Transform.translate(
            offset: Offset(0, -15), // Move up by half the icon height
            child: Icon(
              Icons.navigation,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ));
      }
    }

    return markers;
  }

  Widget _buildStatusSection() {
    return Card(
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Route Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: FluentIcons.ruler_24_regular,
                  label: 'Total Distance',
                  value: '${_totalDistance.toStringAsFixed(2)} km',
                ),
                _buildStatItem(
                  icon: FluentIcons.location_arrow_24_regular,
                  label: 'Remaining',
                  value: '${_remainingDistance.toStringAsFixed(2)} km',
                ),
                _buildStatItem(
                  icon: FluentIcons.vehicle_truck_profile_24_regular,
                  label: 'Completed',
                  value:
                      '${((_totalDistance - _remainingDistance) / _totalDistance * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 4.0),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _calculateDistances();

      // Update location in Firestore
      await _firestore.collection('shipments').doc(widget.shipmentId).update({
        'currentLoc': {
          'lat': position.latitude,
          'lon': position.longitude,
        },
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }
}

// delivery_status_timeline.dart
class DeliveryStatusTimeline extends StatelessWidget {
  final Map<String, dynamic> statuses;

  const DeliveryStatusTimeline({
    super.key,
    required this.statuses,
  });

  IconData _getStatusIcon(String status) {
    final lowercaseStatus = status.toLowerCase();
    if (lowercaseStatus.contains('shipped')) return FluentIcons.vehicle_truck_profile_24_filled;
    if (lowercaseStatus.contains('pickup')) return FluentIcons.box_24_filled;
    if (lowercaseStatus.contains('hub')) return FluentIcons.clock_24_filled;
    return FluentIcons.checkmark_circle_24_filled;
  }

  @override
  Widget build(BuildContext context) {
    final statusEntries = statuses.entries.toList()
      ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16.0),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            itemCount: statusEntries.length,
            itemBuilder: (context, index) {
              final entry = statusEntries[index];
              final date =
                  DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key));
              final status = entry.value as String;

              return TimelineEntry(
                icon: _getStatusIcon(status),
                date: date,
                status: status,
                isLast: index == statusEntries.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class TimelineEntry extends StatelessWidget {
  final IconData icon;
  final DateTime date;
  final String status;
  final bool isLast;

  const TimelineEntry({
    super.key,
    required this.icon,
    required this.date,
    required this.status,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(date),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.5),
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
