import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController _controller;
  Set<Polygon> _polygons = Set();
  String _selectedDamageStatus = 'Ağır Hasarlı';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Harita Uygulaması'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedDamageStatus,
            onChanged: (String newValue) {
              setState(() {
                _selectedDamageStatus = newValue;
                _updatePolygonsColor();
              });
            },
            items: ['Ağır Hasarlı', 'Orta Hasarlı', 'Hafif Hasarlı']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _controller = controller;
                });
              },
              polygons: _polygons,
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12.0,
              ),
              onTap: _onMapTapped,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveToFirebase,
        child: Icon(Icons.save),
      ),
    );
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _polygons.add(Polygon(
        polygonId: PolygonId('building'),
        points: _createPolygonPoints(point),
        fillColor: _getFillColor(),
        strokeWidth: 2,
        strokeColor: Colors.black,
      ));
    });
  }

  List<LatLng> _createPolygonPoints(LatLng center) {
    double offset = 0.001;
    return [
      LatLng(center.latitude + offset, center.longitude - offset),
      LatLng(center.latitude - offset, center.longitude - offset),
      LatLng(center.latitude - offset, center.longitude + offset),
      LatLng(center.latitude + offset, center.longitude + offset),
    ];
  }

  Color _getFillColor() {
    switch (_selectedDamageStatus) {
      case 'Ağır Hasarlı':
        return Colors.red.withOpacity(0.5);
      case 'Orta Hasarlı':
        return Colors.orange.withOpacity(0.5);
      case 'Hafif Hasarlı':
        return Colors.green.withOpacity(0.5);
      default:
        return Colors.transparent;
    }
  }

  void _updatePolygonsColor() {
    setState(() {
      _polygons = _polygons.map((polygon) {
        return polygon.copyWith(fillColorParam: _getFillColor());
      }).toSet();
    });
  }

  void _saveToFirebase() async {
  // Firestore bağlantısını başlatın
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Poligonları Firestore'a ekleyin
  for (Polygon polygon in _polygons) {
    List<GeoPoint> geoPoints = polygon.points.map((latLng) {
      return GeoPoint(latLng.latitude, latLng.longitude);
    }).toList();

    // Firestore'a eklemek istediğiniz verileri belirtin
    Map<String, dynamic> buildingData = {
      'damageStatus': _selectedDamageStatus,
      'polygonPoints': geoPoints,
    };

    // Firestore koleksiyonunu ve belgeyi belirtin
    CollectionReference buildings = firestore.collection('buildings');
    DocumentReference documentReference = await buildings.add(buildingData);

    // Eklenen belgenin ID'sini alabilirsiniz
    print('Building added with ID: ${documentReference.id}');
  }

  // Firestore bağlantısını kapatın (isteğe bağlı)
  // firestore.terminate();
}


}
