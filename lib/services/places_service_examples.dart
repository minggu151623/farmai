/// Ví dụ sử dụng Google Places API trong ứng dụng Flutter
///
/// File này chứa các ví dụ về cách sử dụng PlacesService để:
/// 1. Tìm kiếm địa điểm lân cận
/// 2. Lấy chi tiết địa điểm
/// 3. Tìm kiếm theo văn bản
/// 4. Quản lý vị trí người dùng

// Ví dụ 1: Tìm kiếm nhà hàng lân cận
/*
import 'package:geolocator/geolocator.dart';
import 'lib/services/places_service.dart';

Future<void> findNearbyRestaurants() async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  try {
    // Lấy vị trí hiện tại
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Tìm kiếm nhà hàng trong bán kính 2km
    final response = await placesService.searchNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radius: 2000,
      type: PlaceType.restaurant,
      maxResults: 10,
    );

    if (response != null && response.results.isNotEmpty) {
      for (var place in response.results) {
        print('Nhà hàng: ${place.name}');
        print('Địa chỉ: ${place.formatted_address}');
        print('Điểm số: ${place.rating}');
        print('---');
      }
    } else {
      print('Không tìm thấy nhà hàng nào');
    }
  } catch (e) {
    print('Lỗi: $e');
  }
}
*/

// Ví dụ 2: Tìm kiếm các loại địa điểm khác nhau
/*
Future<void> searchMultipleLocations() async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  final Position position = await Geolocator.getCurrentPosition();

  // Tìm kiếm: nhà hàng, quán cà phê, bệnh viện trong bán kính 3km
  final results = await placesService.searchMultipleTypes(
    latitude: position.latitude,
    longitude: position.longitude,
    radius: 3000,
    types: [
      PlaceType.restaurant,
      PlaceType.cafe,
      PlaceType.hospital,
    ],
  );

  // Xử lý kết quả
  for (var response in results) {
    print('Tìm thấy ${response.results.length} địa điểm');
  }
}
*/

// Ví dụ 3: Lấy chi tiết địa điểm cụ thể
/*
Future<void> getPlaceDetails(String placeId) async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  try {
    final details = await placesService.getPlaceDetails(
      placeId: placeId,
      fields: 'name,formatted_address,rating,user_ratings_total,'
              'opening_hours,website,international_phone_number,photos',
    );

    if (details != null) {
      print('Tên: ${details.name}');
      print('Địa chỉ: ${details.formatted_address}');
      print('Điểm số: ${details.rating}');
      print('Số đánh giá: ${details.user_ratings_total}');
      print('Website: ${details.website}');
      print('Điện thoại: ${details.international_phone_number}');

      // Kiểm tra giờ mở cửa
      if (details.opening_hours != null) {
        print('Mở cửa hôm nay: ${details.opening_hours!.weekday_text}');
      }
    }
  } catch (e) {
    print('Lỗi: $e');
  }
}
*/

// Ví dụ 4: Tìm kiếm theo văn bản
/*
Future<void> searchByText(String query) async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  try {
    final response = await placesService.searchByText(
      query: query,
      latitude: 21.0285,  // Tùy chọn: để ưu tiên kết quả gần vị trí này
      longitude: 105.8542,
    );

    if (response != null && response.results.isNotEmpty) {
      for (var place in response.results) {
        print('${place.name} - ${place.formatted_address}');
      }
    }
  } catch (e) {
    print('Lỗi tìm kiếm: $e');
  }
}
*/

// Ví dụ 5: Tích hợp vào UI (Stateful Widget)
/*
import 'package:flutter/material.dart';

class PlacesSearchWidget extends StatefulWidget {
  @override
  State<PlacesSearchWidget> createState() => _PlacesSearchWidgetState();
}

class _PlacesSearchWidgetState extends State<PlacesSearchWidget> {
  late PlacesService _placesService;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(
      apiKey: 'YOUR_API_KEY_HERE',
    );
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      final Position position = await Geolocator.getCurrentPosition();

      final response = await _placesService.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 1500,
        type: PlaceType.restaurant,
      );

      setState(() {
        _searchResults = response?.results ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _performSearch,
          child: _isLoading
              ? CircularProgressIndicator()
              : Text('Tìm kiếm'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final place = _searchResults[index];
              return ListTile(
                title: Text(place.name ?? 'N/A'),
                subtitle: Text(place.formatted_address ?? 'N/A'),
                trailing: Text('⭐ ${place.rating ?? 'N/A'}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
*/

// Ví dụ 6: Sử dụng NearbySearchScreen
/*
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tìm Kiếm Địa Điểm')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NearbySearchScreen(
                  apiKey: 'YOUR_API_KEY_HERE',
                ),
              ),
            );
          },
          child: Text('Mở Tìm Kiếm Lân Cận'),
        ),
      ),
    );
  }
}
*/

// Ví dụ 7: Quản lý quyền vị trí
/*
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationPermission() async {
  final status = await Permission.location.request();

  if (status.isGranted) {
    print('Quyền vị trí được cấp');
    return true;
  } else if (status.isDenied) {
    print('Quyền vị trí bị từ chối');
    return false;
  } else if (status.isPermanentlyDenied) {
    print('Quyền vị trí bị từ chối vĩnh viễn');
    openAppSettings();
    return false;
  }

  return false;
}

Future<void> startLocationTracking() async {
  bool hasPermission = await requestLocationPermission();

  if (hasPermission) {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Cập nhật mỗi 100m
      ),
    ).listen((Position position) {
      print('Vị trí mới: ${position.latitude}, ${position.longitude}');
      // Cập nhật UI hoặc thực hiện tìm kiếm mới
    });
  }
}
*/

// Ví dụ 8: Lưu trữ cache kết quả tìm kiếm
/*
class PlacesCacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _timestamps = {};

  static const Duration CACHE_DURATION = Duration(hours: 1);

  static void saveCache(String key, dynamic value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  static dynamic getCache(String key) {
    if (_timestamps.containsKey(key)) {
      final cached = _timestamps[key]!;
      final isExpired = DateTime.now().difference(cached) > CACHE_DURATION;

      if (!isExpired) {
        return _cache[key];
      } else {
        clearCache(key);
      }
    }

    return null;
  }

  static void clearCache(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  static void clearAllCache() {
    _cache.clear();
    _timestamps.clear();
  }
}

// Sử dụng
Future<void> searchNearbyWithCache() async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  String cacheKey = 'restaurants_21.0285_105.8542';

  // Kiểm tra cache trước
  var cachedResult = PlacesCacheManager.getCache(cacheKey);

  if (cachedResult != null) {
    print('Sử dụng kết quả từ cache');
  } else {
    final response = await placesService.searchNearby(
      latitude: 21.0285,
      longitude: 105.8542,
      type: PlaceType.restaurant,
    );

    if (response != null) {
      PlacesCacheManager.saveCache(cacheKey, response);
      print('Lưu kết quả vào cache');
    }
  }
}
*/

// Ví dụ 9: Tính khoảng cách giữa vị trí hiện tại và địa điểm
/*
import 'package:geolocator/geolocator.dart';

double calculateDistance(
  double userLat,
  double userLng,
  double placeLat,
  double placeLng,
) {
  return Geolocator.distanceBetween(
    userLat,
    userLng,
    placeLat,
    placeLng,
  );
}

// Xử lý kết quả với khoảng cách
Future<void> searchAndCalculateDistance() async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  final Position position = await Geolocator.getCurrentPosition();

  final response = await placesService.searchNearby(
    latitude: position.latitude,
    longitude: position.longitude,
    type: PlaceType.restaurant,
  );

  if (response != null) {
    final sortedPlaces = response.results.toList();

    // Sắp xếp theo khoảng cách
    sortedPlaces.sort((a, b) {
      double distA = calculateDistance(
        position.latitude,
        position.longitude,
        a.geometry?.location?.lat ?? 0,
        a.geometry?.location?.lng ?? 0,
      );

      double distB = calculateDistance(
        position.latitude,
        position.longitude,
        b.geometry?.location?.lat ?? 0,
        b.geometry?.location?.lng ?? 0,
      );

      return distA.compareTo(distB);
    });

    // In kết quả sắp xếp
    for (var place in sortedPlaces) {
      double distance = calculateDistance(
        position.latitude,
        position.longitude,
        place.geometry?.location?.lat ?? 0,
        place.geometry?.location?.lng ?? 0,
      );

      print('${place.name} - ${(distance / 1000).toStringAsFixed(2)} km');
    }
  }
}
*/

// Ví dụ 10: Error Handling toàn diện
/*
Future<void> robustPlacesSearch() async {
  final placesService = PlacesService(
    apiKey: 'YOUR_API_KEY_HERE',
  );

  try {
    // Kiểm tra dịch vụ vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Dịch vụ vị trí chưa được bật');
      return;
    }

    // Kiểm tra quyền truy cập
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print('Không thể truy cập quyền vị trí');
      return;
    }

    // Lấy vị trí
    final Position position = await Geolocator.getCurrentPosition();

    // Thực hiện tìm kiếm
    final response = await placesService.searchNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      type: PlaceType.restaurant,
    );

    // Kiểm tra kết quả
    if (response == null) {
      print('Không thể lấy dữ liệu từ server');
    } else if (response.results.isEmpty) {
      print('Không tìm thấy kết quả nào');
    } else {
      print('Tìm thấy ${response.results.length} kết quả');
    }
  } on LocationServiceDisabledException {
    print('Dịch vụ vị trí bị vô hiệu hóa');
  } on PermissionDeniedException {
    print('Quyền vị trí bị từ chối');
  } catch (e) {
    print('Lỗi không xác định: $e');
  }
}
*/

void main() {
  print('Đây là file ví dụ. Uncomment các phần cần sử dụng.');
}
