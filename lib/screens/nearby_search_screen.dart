import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/places_service.dart';
import '../theme/design_system.dart';

/// Màn hình tìm kiếm các địa điểm lân cận
class NearbySearchScreen extends StatefulWidget {
  final String apiKey;

  const NearbySearchScreen({
    super.key,
    required this.apiKey,
  });

  @override
  State<NearbySearchScreen> createState() => _NearbySearchScreenState();
}

class _NearbySearchScreenState extends State<NearbySearchScreen> {
  late PlacesService _placesService;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  // State variables
  bool _isLoading = false;
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  LatLng? _selectedLocation;
  String _selectedType = PlaceType.restaurant;
  int _selectedRadius = 1000;
  List<PlaceResult> _searchResults = [];
  bool _showResults = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(apiKey: widget.apiKey);
    _getCurrentLocation();
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ vị trí trên thiết bị'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền vị trí bị từ chối vĩnh viễn. Vào Cài đặt để cấp quyền.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _markers = {
          Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        };
      });

      // Di chuyển camera đến vị trí hiện tại
      final controller = await _mapControllerCompleter.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí hiện tại: $e'),
            backgroundColor: FarmColors.error,
          ),
        );
      }
    }
  }

  /// Khi người dùng chạm vào bản đồ để chọn vị trí
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      // Cập nhật marker vị trí đã chọn
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Vị trí đã chọn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
      _showResults = false;
      _searchResults = [];
    });
  }

  /// Quay về vị trí hiện tại
  Future<void> _goToMyLocation() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }
    setState(() {
      _selectedLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId('my_location'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
    );
  }

  /// Thực hiện tìm kiếm địa điểm lân cận
  Future<void> _searchNearby() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí trên bản đồ hoặc cho phép truy cập vị trí'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = false;
    });

    try {
      final results = await _placesService.searchNearby(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        radius: _selectedRadius,
        type: _selectedType,
      );

      final placeResults = results?.results ?? [];

      // Tạo markers cho kết quả
      final resultMarkers = <Marker>{};
      // Giữ marker vị trí đã chọn
      resultMarkers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      for (int i = 0; i < placeResults.length; i++) {
        final place = placeResults[i];
        if (place.latitude != null && place.longitude != null) {
          resultMarkers.add(
            Marker(
              markerId: MarkerId('place_$i'),
              position: LatLng(place.latitude!, place.longitude!),
              infoWindow: InfoWindow(
                title: place.name ?? 'Địa điểm',
                snippet: place.formattedAddress,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      setState(() {
        _searchResults = placeResults;
        _showResults = true;
        _isLoading = false;
        _markers = resultMarkers;
      });

      // Zoom để thấy tất cả markers
      if (resultMarkers.length > 1) {
        final controller = await _mapControllerCompleter.future;
        final bounds = _boundsFromMarkers(resultMarkers);
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }

      if (placeResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy địa điểm nào trong phạm vi này'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: FarmColors.error,
          ),
        );
      }
    }
  }

  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Mở điện thoại gọi số
  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Kiếm Địa Điểm Lân Cận'),
        elevation: 0,
        backgroundColor: FarmColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingLocation
          ? _buildLoadingWidget()
          : Column(
              children: [
                // Phần bản đồ
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? const LatLng(21.0285, 105.8542),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          if (!_mapControllerCompleter.isCompleted) {
                            _mapControllerCompleter.complete(controller);
                          }
                        },
                        onTap: _onMapTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: _markers,
                        circles: _selectedLocation != null
                            ? {
                                Circle(
                                  circleId: const CircleId('search_radius'),
                                  center: _selectedLocation!,
                                  radius: _selectedRadius.toDouble(),
                                  fillColor: FarmColors.primary.withValues(alpha: 0.1),
                                  strokeColor: FarmColors.primary.withValues(alpha: 0.3),
                                  strokeWidth: 1,
                                ),
                              }
                            : {},
                      ),
                      // Nút quay về vị trí hiện tại
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'my_location',
                          backgroundColor: Colors.white,
                          onPressed: _goToMyLocation,
                          child: const Icon(Icons.my_location, color: FarmColors.primary),
                        ),
                      ),
                      // Hướng dẫn
                      if (_selectedLocation == null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Chạm vào bản đồ để chọn vị trí tìm kiếm',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Phần tìm kiếm
                _buildSearchPanel(),

                // Phần kết quả
                if (_showResults)
                  Expanded(
                    flex: 2,
                    child: _buildResultsList(),
                  ),
              ],
            ),
    );
  }

  /// Xây dựng bảng điều khiển tìm kiếm
  Widget _buildSearchPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: FarmColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Loại địa điểm
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Loại địa điểm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: PlaceType.allTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(PlaceType.getDisplayName(type), style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Nút tìm kiếm
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _searchNearby,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search, size: 20),
                  label: const Text('Tìm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bán kính
          Row(
            children: [
              Text(
                'Bán kính: ${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                style: FarmTextStyles.labelSmall,
              ),
              Expanded(
                child: Slider(
                  value: _selectedRadius.toDouble(),
                  min: 100,
                  max: 50000,
                  divisions: 49,
                  onChanged: (value) {
                    setState(() => _selectedRadius = value.toInt());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng danh sách kết quả
  Widget _buildResultsList() {
    return Container(
      color: FarmColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Kết quả (${_searchResults.length})',
              style: FarmTextStyles.heading3,
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      'Không có kết quả',
                      style: FarmTextStyles.bodyMedium.copyWith(
                        color: FarmColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            // Zoom đến địa điểm trên bản đồ
                            if (place.latitude != null && place.longitude != null) {
                              final controller = await _mapControllerCompleter.future;
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(place.latitude!, place.longitude!),
                                  17,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name ?? 'Không có tên',
                                        style: FarmTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.formattedAddress ?? 'Không có địa chỉ',
                                        style: FarmTextStyles.bodyMedium.copyWith(
                                          color: FarmColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (place.rating != null) ...[
                                            const Icon(Icons.star, size: 16, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${place.rating}',
                                              style: FarmTextStyles.bodyMedium,
                                            ),
                                            const SizedBox(width: 4),
                                            if (place.userRatingCount != null)
                                              Text(
                                                '(${place.userRatingCount})',
                                                style: FarmTextStyles.labelSmall.copyWith(
                                                  color: FarmColors.textSecondary,
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (place.openNow != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: place.openNow!
                                                    ? Colors.green.withValues(alpha: 0.1)
                                                    : Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                place.openNow! ? 'Đang mở' : 'Đã đóng',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: place.openNow! ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Nút gọi điện (nếu có số)
                                if (place.placeId != null)
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: FarmColors.primary),
                                    tooltip: 'Chi tiết',
                                    onPressed: () => _showPlaceDetails(place.placeId!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị chi tiết địa điểm
  Future<void> _showPlaceDetails(String placeId) async {
    final details = await _placesService.getPlaceDetails(placeId: placeId);
    if (details == null || !mounted) return;

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
              Text(
                details.name ?? 'Không có tên',
                style: FarmTextStyles.heading3,
              ),
              const SizedBox(height: 8),
              if (details.formattedAddress != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: FarmColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(details.formattedAddress!, style: FarmTextStyles.bodyMedium),
                    ),
                  ],
                ),
              if (details.internationalPhoneNumber != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _callPhone(details.internationalPhoneNumber!),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: FarmColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        details.internationalPhoneNumber!,
                        style: FarmTextStyles.bodyMedium.copyWith(
                          color: FarmColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('(Nhấn để gọi)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
              if (details.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('${details.rating}', style: FarmTextStyles.bodyMedium),
                    if (details.userRatingCount != null)
                      Text(' (${details.userRatingCount} đánh giá)',
                          style: FarmTextStyles.labelSmall),
                  ],
                ),
              ],
              if (details.website != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(details.website!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.language, size: 16, color: FarmColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          details.website!,
                          style: FarmTextStyles.bodyMedium.copyWith(
                            color: FarmColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Xây dựng widget cho trạng thái đang tải
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang lấy vị trí của bạn...',
            style: FarmTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
