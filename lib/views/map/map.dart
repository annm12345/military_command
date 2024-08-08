import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity/connectivity.dart';
import 'package:militarycommand/colors.dart';
import 'package:militarycommand/images.dart';
import 'package:militarycommand/styles.dart';
import 'package:militarycommand/views/map/compass.dart';
import 'package:militarycommand/views/map/operation_map.dart';
import 'package:militarycommand/views/map/weapon.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:velocity_x/velocity_x.dart';
import 'package:vector_math/vector_math.dart' as vectorMath;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef DecoderCallback = Future<ui.Codec> Function(ImmutableBuffer buffer,
    {int? cacheWidth, int? cacheHeight, bool? allowUpscaling});

class CachedTileProvider extends TileProvider {
  final cacheManager = DefaultCacheManager();

  @override
  ImageProvider getImage(Coords<num> coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CustomCachedNetworkImageProvider(url, cacheManager: cacheManager);
  }

  String getTileUrl(Coords<num> coordinates, TileLayer options) {
    final tileUrl = options.urlTemplate!
        .replaceAll(
            '{s}',
            options.subdomains[(coordinates.x.toInt() + coordinates.y.toInt()) %
                options.subdomains.length])
        .replaceAll('{z}', '${coordinates.z.toInt()}')
        .replaceAll('{x}', '${coordinates.x.toInt()}')
        .replaceAll('{y}', '${coordinates.y.toInt()}');
    return tileUrl;
  }
}

class CustomCachedNetworkImageProvider
    extends ImageProvider<CustomCachedNetworkImageProvider> {
  final String url;
  final BaseCacheManager cacheManager;

  CustomCachedNetworkImageProvider(this.url, {required this.cacheManager});

  @override
  Future<CustomCachedNetworkImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<CustomCachedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      CustomCachedNetworkImageProvider key,
      Future<ui.Codec> Function(ImmutableBuffer,
              {TargetImageSize Function(int, int)? getTargetSize})
          decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('URL', url),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
      CustomCachedNetworkImageProvider key,
      Future<ui.Codec> Function(ImmutableBuffer,
              {TargetImageSize Function(int, int)? getTargetSize})
          decode) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Online: Load and cache the image
        final FileInfo? fileInfo = await cacheManager.getFileFromCache(url);
        if (fileInfo == null || fileInfo.file == null) {
          // Download and cache the file if not present
          final Uint8List? imageData = await cacheManager
              .getSingleFile(url)
              .then((file) => file.readAsBytes());
          if (imageData != null) {
            return decode(await ImmutableBuffer.fromUint8List(imageData));
          } else {
            throw Exception('Failed to load image data.');
          }
        } else {
          // Load from cache
          final bytes = await fileInfo.file.readAsBytes();
          return decode(
              await ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes)));
        }
      } else {
        // Offline: Load from cache
        final file = await cacheManager.getFileFromCache(url);
        if (file?.file != null) {
          final bytes = await file!.file.readAsBytes();
          return decode(
              await ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes)));
        } else {
          throw Exception('Offline and image not found in cache.');
        }
      }
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  LatLng? _dotLocation;
  final double _zoom = 13.0;
  final double _dotSize = 12.0;
  double _bearing = 0.0;
  final MapController _mapController = MapController();
  String _mapType = 'offline';
  bool _isOnline = true;
  List<Map<String, dynamic>> _locations = [];
  String _mgrsString = '';
  TextEditingController _searchController = TextEditingController();
  TextEditingController _deletecontroller = TextEditingController();
  bool _drawCircle = false;
  bool _isMapReady = false;
  double _circleRadius = 4600;
  List<Map<String, dynamic>> _circles = [];
  List<LatLng> _targets = [];
  LatLng? _targetLocation1;
  LatLng? _targetLocation2;
  double _targetDistance = 0.0;
  bool _targetsSet = false;
  List<LatLng> points = [];
  double? distance;
  bool isTargetMode = false; // List to hold points for drawing polyline
  double _totalDistance = 0.0;
  String _selectedColor = 'blue';
  List<Map<String, dynamic>> _nearestLocations = [];
  List<Polyline> _mapPolylines = [];
  double? bearingInMils;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    fetchLocations();
    _loadSavedLocations(); // Load saved locations when the screen loads
    _setupConnectivityListener();

    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove || event is MapEventMoveEnd) {
        setState(() {
          _dotLocation = event.center;
          if (_dotLocation != null) {
            _updateMGRS(_dotLocation!);
          }
        });
      }
    });
  }

  void _toggleOnlineMode() {
    setState(() {
      _isOnline = !_isOnline;
    });
  }

  void _addPoint(LatLng point) {
    if (isTargetMode) {
      setState(() {
        if (points.length == 2) {
          points.clear();
          distance = null;
        }
        points.add(point);
        if (points.length == 2) {
          distance = Distance().as(LengthUnit.Meter, points[0], points[1]);
          double bearingInDegrees = Distance().bearing(points[0], points[1]);
          double bearingInNatoMils =
              bearingInDegrees * (6400 / 360); // Convert degrees to NATO mils

          // Adjust to the range 1 to 6400 mils
          if (bearingInNatoMils < 0) {
            bearingInNatoMils += 6400;
          }
          bearingInMils = bearingInNatoMils;
        }
      });
    } else {
      _findNearestLocations(point);
    }
  }
  // void _findNearestLocations(LatLng tappedLocation) {
  //   final distance = Distance();

  //   List<Map<String, dynamic>> distances = _locations.map((location) {
  //     final latitude = double.tryParse(location['latitude']) ?? 0.0;
  //     final longitude = double.tryParse(location['longitude']) ?? 0.0;
  //     final point = LatLng(latitude, longitude);
  //     final dist = distance.as(LengthUnit.Meter, tappedLocation, point);
  //     return {
  //       'label': location['label'],
  //       'distance': dist,
  //       'point': point,
  //     };
  //   }).toList();

  //   distances.sort((a, b) => a['distance'].compareTo(b['distance']));

  //   setState(() {
  //     _nearestLocations = distances.take(3).toList();
  //   });
  // }
  void _calculateSuitableWeapons() {
    _nearestLocations = _nearestLocations.map((loc) {
      final suitableWeapons = weapons.where((weapon) {
        return (loc['distance'] - 20) <= weapon.range &&
            weapon.range <= (loc['distance'] + 20);
      }).toList();

      return {
        ...loc,
        'suitableWeapons': suitableWeapons,
      };
    }).toList();
  }

  void _findNearestLocations(LatLng tappedLocation) {
    final distance = Distance();

    List<Map<String, dynamic>> blueLocations = _locations.where((location) {
      final colorName = location['color']?.toLowerCase() ?? '';
      return colorName == 'blue';
    }).toList();

    List<Map<String, dynamic>> distances = blueLocations.map((location) {
      final latitude = double.tryParse(location['latitude']) ?? 0.0;
      final longitude = double.tryParse(location['longitude']) ?? 0.0;
      final point = LatLng(latitude, longitude);
      final dist = distance.as(LengthUnit.Meter, tappedLocation, point);
      return {
        'label': location['label'],
        'distance': dist,
        'point': point,
      };
    }).toList();

    distances.sort((a, b) => a['distance'].compareTo(b['distance']));

    setState(() {
      _nearestLocations = distances.take(3).toList();
      _calculateSuitableWeapons();
      _drawRoutes(tappedLocation);
    });
  }

  void _drawRoutes(LatLng tappedLocation) {
    List<Polyline> polylines = _nearestLocations.map((loc) {
      final start = loc['point'];
      final end = tappedLocation;
      final waypoints = _generateWaypoints(start, end);
      return Polyline(
        points: waypoints,
        strokeWidth: 4.0,
        color: Colors.blue,
      );
    }).toList();

    setState(() {
      _mapPolylines = polylines;
    });
  }

  List<LatLng> _generateWaypoints(LatLng start, LatLng end) {
    List<LatLng> waypoints = [];
    const numSteps = 5; // Number of steps in the zigzag pattern

    double latStep = (end.latitude - start.latitude) / numSteps;
    double lngStep = (end.longitude - start.longitude) / numSteps;

    for (int i = 0; i <= numSteps; i++) {
      double offsetLat = start.latitude + i * latStep;
      double offsetLng = start.longitude + i * lngStep;

      // Add an offset for the zigzag effect
      if (i % 2 == 0) {
        offsetLat += 0.001; // Adjust as necessary for a noticeable zigzag
      } else {
        offsetLng += 0.001; // Adjust as necessary for a noticeable zigzag
      }

      waypoints.add(LatLng(offsetLat, offsetLng));
    }

    waypoints.add(end); // Ensure the route ends at the destination
    return waypoints;
  }

  void _toggleTargetMode() {
    setState(() {
      isTargetMode = !isTargetMode;
      if (!isTargetMode) {
        points.clear();
        _mapPolylines.clear();
        distance = null;
      }
    });
  }

  LatLng _getMidPoint() {
    if (points.length < 2) return LatLng(0, 0);
    final lat = (points[0].latitude + points[1].latitude) / 2;
    final lon = (points[0].longitude + points[1].longitude) / 2;
    return LatLng(lat, lon);
  }

  Future<void> fetchLocations() async {
    String uri = "http://militarycommand.atwebpages.com/all_location.php";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _locations = List<Map<String, dynamic>>.from(data);
        });
        await _saveLocations(); // Save locations after fetching
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (error) {
      print('Error fetching locations: $error');
    }
  }

  Future<void> _loadSavedLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLocations = prefs.getString('locations');
    if (savedLocations != null && savedLocations.isNotEmpty) {
      setState(() {
        _locations =
            List<Map<String, dynamic>>.from(json.decode(savedLocations));
      });
      print('Loaded saved locations: $_locations');
    } else {
      print('No saved locations found');
    }
  }

  Future<void> _saveLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locations', json.encode(_locations));
    print('Locations saved');
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // Handle offline mode
        print('No internet connection');
        _loadSavedLocations(); // Load saved locations when offline
      } else {
        // Handle online mode
        print('Connected to internet');
        fetchLocations(); // Re-fetch locations when online
      }
    });
  }

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: Builder(
        builder: (context) {
          return GestureDetector(
            // onTap: () {
            //   _showOptionsBottomSheet(context);
            // },
            child: _currentLocation != null
                ? Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _currentLocation!,
                          zoom: _zoom,
                          maxZoom: 18.0, // Limit max zoom level
                          minZoom: 7.0, // Limit min zoom level
                          onMapReady: () {
                            setState(() {
                              _isMapReady = true;
                            });
                          },
                          onPositionChanged: (position, _) {
                            setState(() {
                              _dotLocation = position.center;
                              if (_dotLocation != null) {
                                _updateMGRS(_dotLocation!);
                              }
                              if (position.zoom != null) {
                                if (position.zoom! > 16 && _isOnline) {
                                  _toggleOnlineMode();
                                } else if (position.zoom! <= 16 && !_isOnline) {
                                  _toggleOnlineMode();
                                }
                              }
                            });
                          },
                          onTap: (tapPosition, latLng) => _addPoint(latLng),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _getMapTypeUrl(),
                            subdomains: ['a', 'b', 'c'],
                            tileProvider: _isOnline
                                ? CachedTileProvider()
                                : CachedTileProvider(),
                          ),
                          MarkerLayer(
                            markers: _buildMarkers() + _buildCircleCenters(),
                          ),
                          PolylineLayer(
                            polylines: _buildPolylines() +
                                // createMgrsGrid() +
                                _mapPolylines +
                                [
                                  Polyline(
                                    points: points,
                                    strokeWidth: 4.0,
                                    color: Color.fromARGB(255, 236, 4, 4),
                                  ),
                                ],
                          ),
                          CircleLayer(
                            circles: _buildCircles(),
                          ),
                        ],
                      ),

                      Positioned(
                        top: 16.0,
                        right: 16.0,
                        child: GestureDetector(
                          onTap: _rotateMapToNorthSouth,
                          child: Transform.rotate(
                            angle: 0.0,
                            child: Icon(Icons.navigation, size: 32.0),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).size.height / 2.15 -
                            _dotSize / 2,
                        left: MediaQuery.of(context).size.width / 2 -
                            _dotSize / 2,
                        child: GestureDetector(
                          onTap: () {
                            _showOptionsBottomSheet(context);
                          },
                          child: Container(
                            width: _dotSize,
                            height: _dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16.0,
                        left: 16.0,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: ui.Color.fromARGB(190, 38, 158, 14)),
                          child: Text(
                            _mgrsString,
                            style: TextStyle(
                                fontSize: 16.0,
                                color:
                                    const ui.Color.fromARGB(255, 255, 255, 255),
                                fontFamily: semibold),
                          ),
                        ),
                      ),
                      if (distance != null)
                        Positioned(
                          top: 50.0,
                          left: 20,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Color.fromARGB(157, 43, 71, 228)),
                            child: Text(
                              'အကွာအဝေး : ${(distance! / 1000).toStringAsFixed(2)} km\n'
                              'ညွန်းရပ်မေးလ်: ${(bearingInMils!).toStringAsFixed(2)} မေလ်း',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16.0,
                                  color: const ui.Color.fromARGB(
                                      255, 230, 224, 224)),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 16.0,
                        left: 16.0,
                        child: GestureDetector(
                          onTap: _toggleOnlineMode,
                          child: Icon(Icons.map, size: 32.0),
                        ),
                      ),
                      Positioned(
                        right: -15.0,
                        top: MediaQuery.of(context).size.height / 2 - 24,
                        child: FloatingActionButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Icon(Icons.menu),
                        ),
                      ),
                      //  Positioned(
                      //   bottom: 150.0,
                      //   right: 16.0,
                      //   child: FloatingActionButton(
                      //     onPressed: _toggleTargetMode,
                      //     child: Icon(isTargetMode ? Icons.cancel : Icons.gps_fixed),
                      //   ),
                      // ),
                      if (_nearestLocations.isNotEmpty)
                        Positioned(
                          bottom: 140.0,
                          left: 16.0,
                          right:
                              16.0, // Add this line to limit the width of the container
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: ui.Color.fromARGB(158, 12, 10, 143)
                                    .withOpacity(0.8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'အနီးဆုံးရောက်ရှိနေသည့်တပ်များ',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _nearestLocations.clear();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                ..._nearestLocations.map((loc) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            15.0), // Add bottom margin between locations
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            '${loc['label']}: ${(loc['distance'] / 1000).toStringAsFixed(2)} km',
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.white),
                                          ),
                                        ),
                                        Text(
                                          'ရောက်ရှိနိုင်သောအကူပစ်လက်နက်ကြီးများ',
                                          style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        ...loc['suitableWeapons']
                                            .map<Widget>((weapon) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom:
                                                    8.0), // Add padding between weapon details
                                            child: RichText(
                                              text: TextSpan(
                                                text:
                                                    'အမျိုးအစား: ${weapon.name}, တာဝေး: ${weapon.range} မီတာ, ကျည်ပျံသန်းချိန်: ${weapon.bulletFlightTime}စက္ကန့်, ယမ်းအား: ${weapon.gunPower}, တာဝေးမေးလ်: ${weapon.longDistance} မေလ်း',
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        )

                      // ..._buildDeleteButtons(),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _toggleTargetMode,
            child: Icon(isTargetMode ? Icons.cancel : Icons.gps_fixed),
          ),
          // SizedBox(height: 16.0),
          // FloatingActionButton(
          //   onPressed: () {
          //     showDialog(
          //       context: context,
          //       builder: (context) => CompassScreen(),
          //     );
          //   },
          //   child: Icon(Icons.compass_calibration),
          // ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: () {
              // Logic to fetch locations here
              fetchLocations();
            },
            child: Icon(Icons.refresh),
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: _goToUserLocation,
            child: Icon(Icons.my_location),
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: () {
              Get.to(Operationmap());
            },
            child: Image.asset(
              operation,
              width: 50,
            ),
          ),
        ],
      ),
    );
  }

  List<Polyline> createMgrsGrid() {
    List<Polyline> gridLines = [];

    double latStart = 10.0;
    double latEnd = 28.0;
    double lonStart = 92.0;
    double lonEnd = 102.0;

    double interval = 0.01; // Set the grid interval as needed

    // Horizontal lines
    for (double lat = latStart; lat <= latEnd; lat += interval) {
      gridLines.add(
        Polyline(
          points: [LatLng(lat, lonStart), LatLng(lat, lonEnd)],
          color: Colors.red,
          strokeWidth: 1.0,
        ),
      );
    }

    // Vertical lines
    for (double lon = lonStart; lon <= lonEnd; lon += interval) {
      gridLines.add(
        Polyline(
          points: [LatLng(latStart, lon), LatLng(latEnd, lon)],
          color: Colors.red,
          strokeWidth: 1.0,
        ),
      );
    }

    return gridLines;
  }

  List<Marker> createGridLabels() {
    List<Marker> labels = [];

    double latStart = 10.0;
    double latEnd = 28.0;
    double lonStart = 92.0;
    double lonEnd = 102.0;

    double interval = 0.02; // Set the label interval as needed

    for (double lat = latStart; lat <= latEnd; lat += interval) {
      for (double lon = lonStart; lon <= lonEnd; lon += interval) {
        labels.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lat, lon),
            builder: (ctx) => Container(
              child: Text(
                '(${MGRSGRID.latLonToMGRS(lat, lon).toString()})',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
          ),
        );
      }
    }

    return labels;
  }

  // void _addPoint(LatLng point) {
  //   setState(() {
  //     _points.add(point); // Add tapped point to polyline points list
  //     if (_points.length > 1) {
  //       _totalDistance += _calculateDistanceforcustom(_points[_points.length - 2], point); // Calculate distance and add to total
  //     }
  //   });
  // }

//   Offset latLngToScreenPosition(LatLng latLng) {
//   var point = _mapController.latLngToScreenPoint(latLng);
//   if (point != null) {
//     return Offset(point.x.toDouble(), point.y.toDouble());
//   } else {
//     return Offset.zero;
//   }
// }

//   List<Widget> _buildDeleteButtons() {
//     List<Widget> deleteButtons = [];

//     for (var location in _locations) {
//       LatLng latLng = LatLng(location['lat'], location['lng']);
//       Offset position = latLngToScreenPosition(latLng);

//       deleteButtons.add(
//         Positioned(
//           top: position.dy,
//           left: position.dx,
//           child: GestureDetector(
//             onTap: () {
//               print(location);
//             },
//             child: Container(
//               padding: EdgeInsets.all(8.0),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8.0),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 2,
//                     blurRadius: 5,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 Icons.delete,
//                 color: Colors.red,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     return deleteButtons;
//   }

  double _calculateDistanceforcustom(LatLng point1, LatLng point2) {
    // Using the Haversine formula to calculate distance between two LatLng points
    const double earthRadius = 6371000; // Radius of the Earth in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    _showSaveLocationForm(context); // Show save location form
                  },
                  child: Text('Save'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    _calculateDistanceAndBearing();
                    Navigator.pop(context);
                  },
                  child: Text('Calculate'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveLocationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedColor =
            _selectedColor; // Local variable to manage color selection
        return AlertDialog(
          title: Text('Save Location'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller:
                        _searchController, // Use your TextEditingController
                    decoration: InputDecoration(labelText: 'Location Name'),
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: selectedColor,
                    decoration: InputDecoration(labelText: 'Select Color'),
                    items: <String>['blue', 'red', 'green'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedColor = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _saveLocationDetails(selectedColor, _dotLocation!);
                      Navigator.pop(context); // Close dialog
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveLocationDetails(
      String? selectedColor, LatLng locationsave) async {
    String locationName = _searchController.text;

    // Define the URL of the PHP script
    String url = 'http://militarycommand.atwebpages.com/save_location_data.php';

    // Create the POST request
    final response = await http.post(
      Uri.parse(url),
      body: {
        'locationName': locationName,
        'color': selectedColor,
        'lat': locationsave.latitude.toString(),
        'lng': locationsave.longitude.toString(),
      },
    );

    if (response.statusCode == 200) {
      // Handle successful response
      print('Response: ${response.body}');
      fetchLocations();
    } else {
      // Handle error response
      print(
          'Failed to save location details. Status code: ${response.statusCode}');
    }
  }

  void _calculateDistanceAndBearing() {
    if (_currentLocation == null || _dotLocation == null) {
      print('Locations not set.');
      return;
    }

    final distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _dotLocation!.latitude,
      _dotLocation!.longitude,
    );

    final bearing = _calculateBearing(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _dotLocation!.latitude,
      _dotLocation!.longitude,
    );

    final bearingInMill = (bearing * (6400 / 360)).toStringAsFixed(2);

    print('အကွာအဝေး: ${distance.toStringAsFixed(2)} km');
    print('ညွှန်းရပ်မေလ်း: $bearingInMill မေလ်း');

    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'အကွာအဝေး: ${distance.toStringAsFixed(2)} km, ညွှန်းရပ်မေလ်း: $bearingInMill မေလ်း'),
        ),
      );
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Radius of the Earth in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = R * c;

    return distance;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _toRadians(lon2 - lon1);

    final double y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final double x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.cos(dLon);
    final double bearing = (math.atan2(y, x) * 180.0 / math.pi + 360) % 360;

    return bearing;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // void _saveLocation() {
  //   print('Location saved!');
  // }

  double _metersToPixels(double meters, double? zoom, double latitude) {
    if (zoom == null) return 0.0;
    double scale = (1 << zoom.toInt()).toDouble();
    double metersPerPixel =
        (156543.03392 * math.cos(latitude * math.pi / 180)) / scale;
    return meters / metersPerPixel;
  }

  void _rotateMapToNorthSouth() {
    _mapController.rotate(_bearing * -1);
  }

  Future<void> _deleteLocationDetails() async {
    String deletelocationName = _deletecontroller.text;

    // Define the URL of the PHP script
    String url =
        'http://militarycommand.atwebpages.com/delete_location_data.php';

    // Create the POST request
    final response = await http.post(
      Uri.parse(url),
      body: {
        'locationName': deletelocationName,
      },
    );
    if (response.statusCode == 200) {
      // Handle successful response
      print('Response: ${response.body}');
      fetchLocations();
    } else {
      // Handle error response
      print(
          'Failed to save location details. Status code: ${response.statusCode}');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                _searchLocation();
              },
            ),
            trailing: ElevatedButton(
              onPressed: _searchLocation,
              child: Text('Search'),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded),
            title: TextField(
              controller: _deletecontroller,
              decoration: InputDecoration(
                hintText: 'delete location',
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                _deleteLocationDetails();
                Navigator.pop(context);
              },
            ),
            trailing: ElevatedButton(
              onPressed: () {
                _deleteLocationDetails();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                if (_dotLocation != null) {
                  _addCircle(_dotLocation!, 4600);
                } else {
                  _addCircle(_currentLocation!, 4600);
                }
                Navigator.pop(context); // Close the drawer
              },
              child: Text('MA7'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                if (_dotLocation != null) {
                  _addCircle(_dotLocation!, 6400);
                } else {
                  _addCircle(_currentLocation!, 6400);
                }
                Navigator.pop(context); // Close the drawer
              },
              child: Text('MA8'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                if (_dotLocation != null) {
                  _addCircle(_dotLocation!, 12000);
                } else {
                  _addCircle(_currentLocation!, 12000);
                }
                Navigator.pop(context); // Close the drawer
              },
              child: Text('120MM'),
            ),
          ),

          ListTile(
            title: ElevatedButton(
              onPressed: () {
                // Handle 122MM button logic here
              },
              child: Text('122MM'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                // Handle 155MM button logic here
              },
              child: Text('155MM'),
            ),
          ),
          // ListTile(
          //   title: ElevatedButton(
          //     onPressed: () {
          //       _clearAllTargets(); // Implement a method to clear all target positions
          //       Navigator.pop(context); // Close the drawer
          //     },
          //     child: Text('Clear Targets'),
          //   ),
          // ),

          ListTile(
            title: ElevatedButton(
              onPressed: () {
                _clearAllCircles();
                Navigator.pop(context);
              },
              child: Text('All Clear'),
            ),
          ),
        ],
      ),
    );
  }

  // void _clearAllTargets() {
  //   setState(() {
  //     _points.clear(); // Clear the list of polyline points
  //     _totalDistance = 0.0; // Reset total distance to zero
  //     // Clear any other state variables related to markers or circles if needed

  //   });
  // }

  void _clearAllCircles() {
    setState(() {
      // _points.clear(); // Clear the list of polyline points
      // _totalDistance = 0.0; // Reset total distance to zero
      // Clear any other state variables related to markers or circles if needed
      _circles.clear();
    });
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    Color getColorFromName(String colorName) {
      switch (colorName.toLowerCase()) {
        case 'blue':
          return Colors.blue;
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        default:
          return Color.fromARGB(255, 13, 214, 147); // Fallback color
      }
    }

    for (var location in _locations) {
      final latitude = double.tryParse(location['latitude']) ?? 0.0;
      final longitude = double.tryParse(location['longitude']) ?? 0.0;
      final point = LatLng(latitude, longitude);
      final label = location['label'] ?? 'Unknown';
      final colorName = location['color'] ?? 'blue';

      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          builder: (ctx) => GestureDetector(
            onTap: () => _showOptionsBottomSheetcustom(context, label),
            child: Container(
              child: Column(
                children: [
                  Icon(
                    Icons.flag,
                    color: getColorFromName(colorName),
                    size: 28.0,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(213, 243, 241, 241),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_currentLocation != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentLocation!,
          builder: (ctx) => Container(
            child: Column(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'My location',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // if (_targetLocation1 != null) {
    //   markers.add(
    //     Marker(
    //       width: 80.0,
    //       height: 80.0,
    //       point: _targetLocation1!,
    //       builder: (ctx) => Icon(Icons.flag, color: Colors.green),
    //     ),
    //   );
    // }

    // if (_targetLocation2 != null) {
    //   markers.add(
    //     Marker(
    //       width: 80.0,
    //       height: 80.0,
    //       point: _targetLocation2!,
    //       builder: (ctx) => Icon(Icons.flag, color: Colors.green),
    //     ),
    //   );
    // }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (_currentLocation == null || _dotLocation == null) {
      return [];
    }
    return [
      Polyline(
        points: [_currentLocation!, _dotLocation!],
        strokeWidth: 4.0,
        color: Colors.red,
      ),
    ];
  }

  List<Marker> _buildCircleCenters() {
    List<Marker> markers = [];
    for (var circle in _circles) {
      final latitude = circle['latitude'] ?? 0.0;
      final longitude = circle['longitude'] ?? 0.0;
      final point = LatLng(latitude, longitude);

      markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: point,
          builder: (ctx) => GestureDetector(
            onTap: () => _showRemoveCircleDialog(point),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40.0,
                  height: 40.0,
                  child: Icon(
                    Icons.circle,
                    color: Colors.blue,
                    size: 16.0,
                  ),
                ),
                Positioned(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 24.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<CircleMarker> _buildCircles() {
    List<CircleMarker> circleMarkers = [];
    for (var circle in _circles) {
      final latitude = circle['latitude'] ?? 0.0;
      final longitude = circle['longitude'] ?? 0.0;
      final radius = circle['radius'] ?? 100.0;

      final circleMarker = CircleMarker(
        point: LatLng(latitude, longitude),
        radius: _metersToPixels(radius, _mapController.zoom, latitude),
        color: Colors.blue.withOpacity(0.0),
        borderStrokeWidth: 2,
        borderColor: ui.Color.fromARGB(255, 182, 0, 24),
      );

      circleMarkers.add(circleMarker);
    }
    return circleMarkers;
  }

  void _showRemoveCircleDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove Circle"),
        content: Text("Do you want to remove this circle?"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: Text("Remove"),
            onPressed: () {
              _removeCircle(point);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _addCircle(LatLng location, double radius) {
    setState(() {
      _circles.add({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radius': radius,
      });
    });
  }

  void _removeCircle(LatLng location) {
    setState(() {
      _circles.removeWhere((circle) =>
          circle['latitude'] == location.latitude &&
          circle['longitude'] == location.longitude);
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateMGRS(_currentLocation!);
      });
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void _goToUserLocation() async {
    await _getUserLocation();
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, _zoom);
    }
  }

  // void _toggleMapType() {
  //   setState(() {
  //     if (_mapType == 'openstreetmap') {
  //       _mapType = 'google';
  //     } else {
  //       _mapType = 'openstreetmap';
  //     }
  //   });
  // }

  String _getMapTypeUrl() {
    if (_isOnline) {
      // return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    } else {
      return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
    }
  }

  void _searchLocation() {
    String searchLabel = _searchController.text.toLowerCase();
    Map<String, dynamic> location = _locations.firstWhere(
      (location) => location['label'].toString().toLowerCase() == searchLabel,
      orElse: () => {}, // Provide an empty map as default value
    );

    if (location.isNotEmpty) {
      LatLng searchedLocation = LatLng(
        double.parse(location['latitude']),
        double.parse(location['longitude']),
      );
      setState(() {
        _mapController.move(searchedLocation, 17);
        _dotLocation = searchedLocation;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location not found'),
        ),
      );
    }
  }

  void _updateMGRS(LatLng location) {
    _mgrsString =
        MGRS.latLonToMGRS(location.latitude, location.longitude).toString();
    setState(() {});
  }

  void _showOptionsBottomSheetcustom(BuildContext context, label) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: new Icon(Icons.add),
              title: new Text('Add Circle'),
              onTap: () {
                setState(() {
                  _drawCircle = true;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: new Icon(Icons.remove),
              title: new Text('Remove Circle'),
              onTap: () {
                setState(() {
                  _drawCircle = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }
}

class MGRS {
  static final List<String> zoneLetters = [
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'M',
    'N',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X'
  ];

  static final List<String> e100kLetters = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];

  static final List<String> n100kLetters = [
    'ABCDEFGHJKLMNPQRSTUV',
    'FGHJKLMNPQRSTUVABCDE'
  ];

  static String latLonToMGRS(double lat, double lon) {
    if (lat < -80) return 'Too far South';
    if (lat > 84) return 'Too far North';

    int zoneNumber = ((lon + 180) / 6).floor() + 1;
    double e = zoneNumber * 6 - 183;
    double latRad = lat * (pi / 180);
    double lonRad = lon * (pi / 180);
    double centralMeridianRad = e * (pi / 180);
    double cosLat = cos(latRad);
    double sinLat = sin(latRad);
    double tanLat = tan(latRad);
    double tanLat2 = tanLat * tanLat;
    double tanLat4 = tanLat2 * tanLat2;

    double N = 6378137.0 / sqrt(1 - 0.00669438 * sinLat * sinLat);
    double T = tanLat2;
    double C = 0.006739496819936062 * cosLat * cosLat;
    double A = cosLat * (lonRad - centralMeridianRad);
    double M = 6367449.14570093 *
        (latRad -
            (0.00251882794504 * sin(2 * latRad)) +
            (0.00000264354112 * sin(4 * latRad)) -
            (0.00000000345262 * sin(6 * latRad)) +
            (0.000000000004892 * sin(8 * latRad)));

    double x = (A +
            (1 - T + C) * A * A * A / 6 +
            (5 - 18 * T + T * T + 72 * C - 58 * 0.006739496819936062) *
                A *
                A *
                A *
                A *
                A /
                120) *
        N;
    double y = (M +
            N *
                tanLat *
                (A * A / 2 +
                    (5 - T + 9 * C + 4 * C * C) * A * A * A * A / 24 +
                    (61 -
                            58 * T +
                            T * T +
                            600 * C -
                            330 * 0.006739496819936062) *
                        A *
                        A *
                        A *
                        A *
                        A *
                        A /
                        720)) *
        0.9996;

    x = x * 0.9996 + 500000.0;
    y = y * 0.9996;
    if (y < 0.0) {
      y += 10000000.0;
    }

    String zoneLetter = zoneLetters[((lat + 80) / 8).floor()];
    int e100kIndex = ((x / 100000).floor() % 8);
    int n100kIndex = ((y / 100000).floor() % 20);

    String e100kLetter = e100kLetters[(zoneNumber - 1) % 3][e100kIndex];
    String n100kLetter = n100kLetters[(zoneNumber - 1) % 2][n100kIndex];

    String easting = x.round().toString().padLeft(6, '0');
    easting = easting.substring(
        1, 6); // Remove the first character, keep the next 5 characters

    // Convert easting back to an integer, sum with 300, and convert back to a string
    easting = (int.parse(easting) + 350).toString().padLeft(5, '0');

    // Convert y to a string, pad it to at least 7 characters, and remove the first 2 characters
    String northing = y.round().toString().padLeft(7, '0');
    northing = northing.substring(
        2, 7); // Remove the first 2 characters, keep the next 5 characters

    // Convert northing back to an integer, sum with 300, and convert back to a string
    northing = (int.parse(northing) + 700).toString().padLeft(5, '0');

    return '$zoneNumber$zoneLetter $e100kLetter$n100kLetter $easting $northing';
  }
}

class MGRSGRID {
  static final List<String> zoneLetters = [
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'M',
    'N',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X'
  ];

  static final List<String> e100kLetters = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];

  static final List<String> n100kLetters = [
    'ABCDEFGHJKLMNPQRSTUV',
    'FGHJKLMNPQRSTUVABCDE'
  ];

  static String latLonToMGRS(double lat, double lon) {
    if (lat < -80) return 'Too far South';
    if (lat > 84) return 'Too far North';

    int zoneNumber = ((lon + 180) / 6).floor() + 1;
    double e = zoneNumber * 6 - 183;
    double latRad = lat * (pi / 180);
    double lonRad = lon * (pi / 180);
    double centralMeridianRad = e * (pi / 180);
    double cosLat = cos(latRad);
    double sinLat = sin(latRad);
    double tanLat = tan(latRad);
    double tanLat2 = tanLat * tanLat;
    double tanLat4 = tanLat2 * tanLat2;

    double N = 6378137.0 / sqrt(1 - 0.00669438 * sinLat * sinLat);
    double T = tanLat2;
    double C = 0.006739496819936062 * cosLat * cosLat;
    double A = cosLat * (lonRad - centralMeridianRad);
    double M = 6367449.14570093 *
        (latRad -
            (0.00251882794504 * sin(2 * latRad)) +
            (0.00000264354112 * sin(4 * latRad)) -
            (0.00000000345262 * sin(6 * latRad)) +
            (0.000000000004892 * sin(8 * latRad)));

    double x = (A +
            (1 - T + C) * A * A * A / 6 +
            (5 - 18 * T + T * T + 72 * C - 58 * 0.006739496819936062) *
                A *
                A *
                A *
                A *
                A /
                120) *
        N;
    double y = (M +
            N *
                tanLat *
                (A * A / 2 +
                    (5 - T + 9 * C + 4 * C * C) * A * A * A * A / 24 +
                    (61 -
                            58 * T +
                            T * T +
                            600 * C -
                            330 * 0.006739496819936062) *
                        A *
                        A *
                        A *
                        A *
                        A *
                        A /
                        720)) *
        0.9996;

    x = x * 0.9996 + 500000.0;
    y = y * 0.9996;
    if (y < 0.0) {
      y += 10000000.0;
    }

    String zoneLetter = zoneLetters[((lat + 80) / 8).floor()];
    int e100kIndex = ((x / 100000).floor() % 8);
    int n100kIndex = ((y / 100000).floor() % 20);

    String e100kLetter = e100kLetters[(zoneNumber - 1) % 3][e100kIndex];
    String n100kLetter = n100kLetters[(zoneNumber - 1) % 2][n100kIndex];

    String easting = x.round().toString().substring(1).padLeft(1, '0');
    String northing = y.round().toString().substring(2).padLeft(2, '0');

    return '$easting $northing';
  }
}

class OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords coords, TileLayer options) {
    return TileImageProvider(coords, options);
  }
}

class TileImageProvider extends ImageProvider<TileImageProvider> {
  final Coords coords;
  final TileLayer options;

  TileImageProvider(this.coords, this.options);

  ImageStreamCompleter load(
      TileImageProvider key, ImageDecoderCallback decode) {
    final streamController = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _fetchAndDecode(key, decode, streamController),
      chunkEvents: streamController.stream,
      scale: 1.0,
    );
  }

  Future<ui.Codec> _fetchAndDecode(
      TileImageProvider key,
      ImageDecoderCallback decode,
      StreamController<ImageChunkEvent> streamController) async {
    final file = await _getLocalTile(key.coords, key.options);
    final bytes = await file.readAsBytes();
    return decode(Uint8List.fromList(bytes) as ui.ImmutableBuffer);
  }

  @override
  Future<TileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TileImageProvider>(this);
  }

  Future<File> _getLocalTile(Coords<num> coords, TileLayer options) async {
    final directory = Directory.systemTemp;
    final filePath = path.join(
        directory.path,
        'tiles',
        options.urlTemplate!.replaceAll(RegExp(r'[/:{}]'), '_'),
        '${coords.z}',
        '${coords.x}',
        '${coords.y}.png');
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    } else {
      return await _downloadAndSaveTile(coords, options, file);
    }
  }

  Future<File> _downloadAndSaveTile(
      Coords<num> coords, TileLayer options, File file) async {
    final url = options.urlTemplate!
        .replaceFirst('{s}', 'a')
        .replaceFirst('{z}', coords.z.toString())
        .replaceFirst('{x}', coords.x.toString())
        .replaceFirst('{y}', coords.y.toString());

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      // Handle errors such as failed host lookup
      print('Error downloading tile: $e');
    }

    return file;
  }
}

class AssetTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords coordinates, TileLayer options) {
    final tilePath =
        'assets/maptiles/${coordinates.z.toInt()}/${coordinates.x.toInt()}/${coordinates.y.toInt()}.png';
    return AssetImage(tilePath);
  }
}
