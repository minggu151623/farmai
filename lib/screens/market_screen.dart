import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/design_system.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final String phone;
  final double rating;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.phone,
    required this.rating,
  });
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isSearching = false;
  List<Pharmacy> _pharmacies = [];
  Timer? _debounce;

  static const String _apiKey = 'AIzaSyCANO4HUVzxsuo_8ABxALBW9VgTbEYeMbM';

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.location_on_rounded, 'label': 'Gần nhất', 'id': 'closest'},
    {'icon': Icons.star_rounded, 'label': 'Đánh giá cao', 'id': 'rating'},
    {'icon': Icons.call_rounded, 'label': 'Gọi ngay', 'id': 'call'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty && _currentPosition != null) {
        _searchPharmacies(query);
      } else if (query.isEmpty && _currentPosition != null) {
        _loadNearbyPharmacies();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      await _loadNearbyPharmacies();

      if (_mapControllerCompleter.isCompleted) {
        final controller = await _mapControllerCompleter.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadNearbyPharmacies() async {
    if (_currentPosition == null) return;

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      ).replace(queryParameters: {
        'location': '${_currentPosition!.latitude},${_currentPosition!.longitude}',
        'rankby': 'distance',
        'type': 'pharmacy',
        'language': 'vi',
        'key': _apiKey,
      });

      final response = await http.get(uri);
      debugPrint('Places API nearby: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        debugPrint('Places API status: $status');
        if (status == 'OK') {
          final results = data['results'] as List<dynamic>? ?? [];
          _updatePharmaciesFromResults(results);
        } else {
          final errorMsg = data['error_message'] as String? ?? status;
          debugPrint('Places API error: $errorMsg');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Places API: $errorMsg'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải nhà thuốc: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchPharmacies(String query) async {
    if (_currentPosition == null) return;

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json',
      ).replace(queryParameters: {
        'query': query,
        'location': '${_currentPosition!.latitude},${_currentPosition!.longitude}',
        'language': 'vi',
        'key': _apiKey,
      });

      final response = await http.get(uri);
      debugPrint('Places API search: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        debugPrint('Places API status: $status');
        if (status == 'OK') {
          final results = data['results'] as List<dynamic>? ?? [];
          _updatePharmaciesFromResults(results);
        } else {
          final errorMsg = data['error_message'] as String? ?? status;
          debugPrint('Places API error: $errorMsg');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Places API: $errorMsg'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tìm kiếm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _updatePharmaciesFromResults(List<dynamic> results) {
    var pharmacies = <Pharmacy>[];
    for (int i = 0; i < results.length; i++) {
      final place = results[i] as Map<String, dynamic>;
      final geometry = place['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) continue;

      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();

      double dist = 0;
      if (_currentPosition != null) {
        dist = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) / 1000;
      }

      pharmacies.add(Pharmacy(
        id: place['place_id'] as String? ?? '$i',
        name: place['name'] as String? ?? 'Không có tên',
        address: place['vicinity'] as String? ?? place['formatted_address'] as String? ?? '',
        latitude: lat,
        longitude: lng,
        distance: dist,
        phone: '',
        rating: (place['rating'] as num?)?.toDouble() ?? 0,
      ));
    }

    pharmacies.sort((a, b) => a.distance.compareTo(b.distance));

    // Chỉ lấy 4 nhà thuốc gần nhất
    if (pharmacies.length > 4) {
      pharmacies = pharmacies.sublist(0, 4);
    }

    if (mounted) {
      setState(() {
        _pharmacies = pharmacies;
      });
    }
  }

  Future<void> _goToMyLocation() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      ),
    );
  }

  Future<void> _openInGoogleMaps(Pharmacy pharmacy) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    for (int i = 0; i < _pharmacies.length; i++) {
      final pharmacy = _pharmacies[i];
      markers.add(
        Marker(
          markerId: MarkerId('pharmacy_${pharmacy.id}'),
          position: LatLng(pharmacy.latitude, pharmacy.longitude),
          infoWindow: InfoWindow(
            title: pharmacy.name,
            snippet: pharmacy.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            _showPharmacyBottomSheet(pharmacy);
          },
        ),
      );
    }

    return markers;
  }

  void _showPharmacyBottomSheet(Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pharmacy.name, style: FarmTextStyles.heading3),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: FarmColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(pharmacy.address, style: FarmTextStyles.bodyMedium),
                  ),
                ],
              ),
              if (pharmacy.rating > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('${pharmacy.rating}', style: FarmTextStyles.bodyMedium),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: FarmColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(_formatDistance(pharmacy.distance), style: FarmTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openInGoogleMaps(pharmacy);
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                    ),
                  ),
                  if (pharmacy.phone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callPhone(pharmacy.phone);
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Gọi điện'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  Future<void> _callPhone(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')),
        );
      }
    }
  }

  void _onQuickActionTap(String actionId) {
    switch (actionId) {
      case 'closest':
        setState(() {
          _pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
        });
        break;
      case 'rating':
        setState(() {
          _pharmacies.sort((a, b) => b.rating.compareTo(a.rating));
        });
        break;
      case 'call':
        if (_pharmacies.isNotEmpty) {
          final closest = _pharmacies.first;
          if (closest.phone.isNotEmpty) {
            _callPhone(closest.phone);
          } else {
            _openInGoogleMaps(closest);
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F9F5),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: FarmColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && _currentPosition != null) {
                  _searchPharmacies(value.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Tìm nhà thuốc (VD: Long Châu, An Khang...)',
                hintStyle: FarmTextStyles.bodyMedium.copyWith(
                  color: FarmColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.search, color: FarmColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadNearbyPharmacies();
                        },
                      )
                    : null,
                filled: true,
                fillColor: FarmColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Quick Actions — compact
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: 62,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickActions.length,
                itemBuilder: (context, index) {
                  final action = _quickActions[index];
                  return GestureDetector(
                    onTap: () => _onQuickActionTap(action['id']),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: FarmColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FarmColors.surfaceVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: FarmColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              action['icon'],
                              color: FarmColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action['label'],
                            textAlign: TextAlign.center,
                            style: FarmTextStyles.labelSmall.copyWith(
                              fontSize: 9,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton(
                  icon: Icons.map_rounded,
                  label: 'Bản đồ',
                  isSelected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  icon: Icons.list_rounded,
                  label: 'Danh sách',
                  isSelected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                const Spacer(),
                if (_isSearching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (!_isSearching && _pharmacies.isNotEmpty)
                  Text(
                    '${_pharmacies.length} kết quả',
                    style: FarmTextStyles.labelSmall.copyWith(color: FarmColors.textSecondary),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Map or List View
          Expanded(
            child: _tabIndex == 0 ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(21.0285, 105.8542);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.surfaceVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(controller);
                }
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      14,
                    ),
                  );
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _buildMarkers(),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: FloatingActionButton.small(
                heroTag: 'market_my_location',
                backgroundColor: Colors.white,
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location, color: FarmColors.primary, size: 20),
              ),
            ),
            if (_isLoadingLocation)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_pharmacies.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy_outlined, size: 48, color: FarmColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              _isLoadingLocation ? 'Đang lấy vị trí...' : 'Không tìm thấy nhà thuốc',
              style: FarmTextStyles.bodyMedium.copyWith(color: FarmColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) => _buildPharmacyListItem(_pharmacies[index]),
    );
  }

  Widget _buildPharmacyListItem(Pharmacy pharmacy) {
    return GestureDetector(
      onTap: () => _showPharmacyBottomSheet(pharmacy),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FarmColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FarmColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FarmColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_pharmacy,
                color: FarmColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: FarmTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: FarmColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _formatDistance(pharmacy.distance),
                        style: FarmTextStyles.labelSmall.copyWith(
                          color: FarmColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (pharmacy.rating > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(pharmacy.rating.toStringAsFixed(1), style: FarmTextStyles.labelSmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pharmacy.address,
                    style: FarmTextStyles.labelSmall.copyWith(color: FarmColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openInGoogleMaps(pharmacy),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FarmColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions,
                  color: FarmColors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FarmColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? FarmColors.primary : FarmColors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? FarmColors.primary : FarmColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: FarmTextStyles.labelSmall.copyWith(
                color: isSelected ? FarmColors.primary : FarmColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

