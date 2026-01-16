import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  final Function(LatLng, String) onLocationPicked; // Update: Kirim Alamat juga
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    required this.onLocationPicked,
    this.initialLocation = const LatLng(
      -6.200000,
      106.816666,
    ), // Default Jakarta
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _pickedLocation;
  GoogleMapController? _mapController;

  // API Key (Diambil dari AndroidManifest Anda)
  final String _apiKey = 'AIzaSyChxVZR95gk9-Ij5Z3FuXkbAEyHAywhShg';

  // Variabel untuk Pencarian
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickedLocation, 17),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Fungsi saat user mengetik (Debounce 1 detik agar tidak spam request)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // Logika mencari lokasi dari teks
  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      // Menggunakan Places API (New)
      // Endpoint: https://places.googleapis.com/v1/places:autocomplete
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': ['id'], // Batasi Indonesia
        }),
      );

      debugPrint("Places API (New) Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Struktur response New API: { "suggestions": [ { "placePrediction": { ... } } ] }
        List<dynamic> suggestions = data['suggestions'] ?? [];

        List<Map<String, dynamic>> results = suggestions.map((s) {
          final prediction = s['placePrediction'];
          return {
            'description': prediction['text']['text'],
            'place_id': prediction['placeId'],
          };
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
        return;
      } else {
        final data = json.decode(response.body);
        debugPrint("Places API Error: ${data['error']?['message']}");
      }

      // Jika gagal atau status bukan OK
      throw Exception('Gagal mengambil data');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  // Saat user memilih salah satu saran
  Future<void> _selectSearchResult(String placeId, String description) async {
    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus();

    try {
      // Menggunakan Places API (New) - Place Details
      // Endpoint: https://places.googleapis.com/v1/places/{placeId}
      final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');

      final response = await http.get(
        url,
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'location', // Wajib FieldMask untuk hemat biaya & latency
        },
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final location = data['location'];
        final lat = location['latitude'];
        final lng = location['longitude'];
        final latLng = LatLng(lat, lng);

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));

        setState(() {
          _pickedLocation = latLng;
          _searchResults = [];
          _searchController.text = description;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
      // Handle error silently or show toast
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Agar peta tidak terdorong keyboard
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Ambil alamat dari teks pencarian jika ada, atau koordinat
              widget.onLocationPicked(
                _pickedLocation,
                _searchController.text.isNotEmpty
                    ? _searchController.text
                    : "Lokasi Terpilih",
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              // Update posisi saat map digeser
              _pickedLocation = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled:
                false, // Hilangkan tombol zoom bawaan agar rapi
          ),
          // Marker statis di tengah layar
          const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),

          // --- SEARCH BAR & HASIL PENCARIAN ---
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Cari alamat (cth: Monas, Jakarta)",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // List Hasil Pencarian
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = _searchResults[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            title: Text(
                              item['description'],
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(
                              item['place_id'],
                              item['description'],
                            ),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tombol Lokasi Saya (My Location)
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              heroTag: "my_location_fab",
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF1565C0)),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                // Reverse Geocode posisi pin terakhir untuk akurasi maksimal
                String fullAddress = _searchController.text;
                try {
                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    _pickedLocation.latitude,
                    _pickedLocation.longitude,
                  );
                  if (placemarks.isNotEmpty) {
                    var p = placemarks.first;
                    fullAddress = [
                      p.street, // Jalan + No (biasanya)
                      p.subLocality, // Kelurahan
                      p.locality, // Kecamatan/Kota
                      p.administrativeArea, // Provinsi
                      p.postalCode, // Kode Pos
                    ].where((e) => e != null && e.isNotEmpty).join(', ');
                  }
                } catch (e) {
                  if (fullAddress.isEmpty)
                    fullAddress =
                        "Lokasi (${_pickedLocation.latitude}, ${_pickedLocation.longitude})";
                }

                widget.onLocationPicked(_pickedLocation, fullAddress);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Pilih Lokasi Ini'),
            ),
          ),
        ],
      ),
    );
  }
}
