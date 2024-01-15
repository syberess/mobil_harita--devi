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
      print("hayat");
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
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            _controller = controller;
          });
        },
        polygons: _polygons,
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Başlangıç konumu (örnek olarak San Francisco)
          zoom: 12.0,
        ),
        onTap: _onMapTapped,
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
        fillColor: _selectedDamageStatus == 'Ağır Hasarlı'
            ? Colors.red.withOpacity(0.5)
            : Colors.green.withOpacity(0.5),
        strokeWidth: 2,
        strokeColor: Colors.black,
      ));
    });
  }

  List<LatLng> _createPolygonPoints(LatLng center) {
    // Poligon noktalarını oluşturun (örneğin, dikdörtgen)
    double offset = 0.001;
    return [
      LatLng(center.latitude + offset, center.longitude - offset),
      LatLng(center.latitude - offset, center.longitude - offset),
      LatLng(center.latitude - offset, center.longitude + offset),
      LatLng(center.latitude + offset, center.longitude + offset),
    ];
  }

  import 'package:cloud_firestore/cloud_firestore.dart';

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
