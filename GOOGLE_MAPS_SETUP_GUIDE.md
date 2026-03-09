# Hướng Dẫn Tích Hợp Google Maps Places API - Nearby Search

## Tổng Quan

Tài liệu này hướng dẫn bạn cách tích hợp Google Maps Places API (Nearby Search) vào ứng dụng Flutter trên Android.

## Các Bước Đã Hoàn Thành

### 1. ✅ Cập Nhật Dependencies

Các package sau đã được thêm vào `pubspec.yaml`:
- `google_places_flutter: ^2.0.8` - Flutter wrapper cho Google Places SDK
- `geolocator: ^12.0.0` - Để lấy vị trí hiện tại
- `google_maps_flutter: ^2.14.0` - Sẵn có (để hiển thị bản đồ)

**File cập nhật**: `pubspec.yaml`

```yaml
dependencies:
  google_maps_flutter: ^2.14.0
  google_places_flutter: ^2.0.8
  geolocator: ^12.0.0
```

### 2. ✅ Service Class - PlacesService

Đã tạo class `PlacesService` để xử lý tất cả các hoạt động liên quan đến Places API.

**File**: `lib/services/places_service.dart`

**Các method chính:**
```dart
// Tìm kiếm địa điểm lân cận theo loại
Future<SearchNearbyResponse?> searchNearby({
  required double latitude,
  required double longitude,
  int radius = 1000,
  String? type,
  String language = 'vi',
  int maxResults = 10,
})

// Tìm kiếm nhiều loại cùng lúc
Future<List<SearchNearbyResponse>> searchMultipleTypes({
  required double latitude,
  required double longitude,
  int radius = 1000,
  required List<String> types,
})

// Lấy chi tiết của một địa điểm
Future<PlaceDetails?> getPlaceDetails({
  required String placeId,
  String fields = '...',
})

// Tìm kiếm theo văn bản
Future<SearchNearbyResponse?> searchByText({
  required String query,
  double? latitude,
  double? longitude,
  String language = 'vi',
})
```

**Loại địa điểm có sẵn:**
```dart
PlaceType.restaurant      // Nhà hàng
PlaceType.cafe           // Quán cà phê
PlaceType.hospital       // Bệnh viện
PlaceType.pharmacy       // Nhà thuốc
PlaceType.hotel          // Khách sạn
PlaceType.bank           // Ngân hàng
PlaceType.supermarket    // Siêu thị
// ... và nhiều loại khác
```

### 3. ✅ Ui Screen - NearbySearchScreen

Đã tạo màn hình hoàn chỉnh để demo tính năng Nearby Search.

**File**: `lib/screens/nearby_search_screen.dart`

**Tính năng:**
- Hiển thị bản đồ Google Maps với vị trí hiện tại
- Lựa chọn loại địa điểm (Dropdown)
- Điều chỉnh bán kính tìm kiếm (Slider: 0.1 - 50 km)
- Thực hiện tìm kiếm và hiển thị kết quả
- Hiển thị tên, địa chỉ, rating của các địa điểm tìm được

## Yêu Cầu Thêm - Cần Cấu Hình

### 1. Lấy Google Maps API Key

#### Bước 1: Truy cập Google Cloud Console
1. Vào https://console.cloud.google.com
2. Tạo project mới hoặc chọn project hiện có
3. Bật các API sau:
   - **Maps SDK for Android**
   - **Places API**
   - **Maps JavaScript API** (nếu dùng web)

#### Bước 2: Tạo API Key
1. Vào **Credentials** → **Create Credentials** → **API Key**
2. Giới hạn API Key cho Android và nhập SHA-1 fingerprint của ứng dụng

#### Bước 3: Tìm SHA-1 Fingerprint
```bash
# Chạy lệnh này để lấy SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Hoặc sử dụng gradle:
```bash
cd android
./gradlew signingReport
```

#### Bước 4: Thêm API Key vào AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

### 2. Cấu Hình Quyền Truy Cập Vị Trí

**File**: `android/app/src/main/AndroidManifest.xml`

Đã có:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**Trong Flutter code**, yêu cầu quyền runtime:
```dart
import 'package:permission_handler/permission_handler.dart';

// Yêu cầu quyền vị trí
final status = await Permission.location.request();
if (status.isGranted) {
  // Quyền đã được cấp
}
```

### 3. Cấu Hình Android được Yêu Cầu

Những file đã được kiểm tra và có đủ cấu hình:
- ✅ `android/build.gradle.kts` - Có repositories đúng (google, mavenCentral)
- ✅ `android/app/build.gradle.kts` - Có Java 17 support
- ✅ `android/app/src/main/AndroidManifest.xml` - Có quyền cần thiết

## Cách Sử Dụng

### 1. Nhập Libraries
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/services/places_service.dart';
```

### 2. Khởi Tạo PlacesService
```dart
final placesService = PlacesService(
  apiKey: 'YOUR_API_KEY_HERE'
);
```

### 3. Tìm Kiếm Địa Điểm Lân Cận
```dart
// Tìm nhà hàng gần vị trí hiện tại (bán kính 1km)
final response = await placesService.searchNearby(
  latitude: 21.0285,
  longitude: 105.8542,
  radius: 1000,
  type: PlaceType.restaurant,
);

if (response != null) {
  final places = response.results;
  for (var place in places) {
    print('${place.name} - ${place.formatted_address}');
  }
}
```

### 4. Sử Dụng NearbySearchScreen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NearbySearchScreen(
      apiKey: 'YOUR_API_KEY_HERE',
    ),
  ),
);
```

## Ví Dụ Sử Dụng Nâng Cao

### Tìm Kiếm Nhiều Loại Cùng Lúc
```dart
final results = await placesService.searchMultipleTypes(
  latitude: 21.0285,
  longitude: 105.8542,
  radius: 2000,
  types: [
    PlaceType.restaurant,
    PlaceType.cafe,
    PlaceType.hospital,
  ],
);
```

### Lấy Chi Tiết Địa Điểm
```dart
final details = await placesService.getPlaceDetails(
  placeId: 'ChIJLcMPW7ZAc2gR...',
  fields: 'name,formatted_address,rating,website,photos',
);

print('Tên: ${details?.name}');
print('Điểm: ${details?.rating}');
print('Website: ${details?.website}');
```

### Tìm Kiếm Theo Văn Bản
```dart
final response = await placesService.searchByText(
  query: 'quán cà phê võng',
  latitude: 21.0285,
  longitude: 105.8542,
);
```

## Thông Số Bắt Buộc (Theo Tài Liệu Google)

### 1. Field List (Danh Sách Trường)
Phải chỉ định ít nhất 1 trường dữ liệu cần trả về:
```dart
final List<String> fields = [
  'name',              // Tên địa điểm
  'formatted_address', // Địa chỉ đầy đủ
  'rating',            // Đánh giá
  'user_rating_count', // Số lượng đánh giá
  'photos',            // Ảnh
  'website',           // Website
];
```

### 2. Location Restriction (Hạn Chế Vị Trí)
Phải cung cấp:
- Tâm của vòng tròn tìm kiếm (latitude, longitude)
- Bán kính tìm kiếm (0 < radius ≤ 50,000 mét)

### 3. Thông Số Tùy Chọn
- **includedTypes**: Chỉ tìm loại nhất định
- **excludedTypes**: Loại trừ các loại cụ thể
- **maxResultCount**: Số kết quả tối đa (1-20)
- **rankPreference**: POPULARITY (default) hoặc DISTANCE
- **regionCode**: Mã khu vực (VN cho Việt Nam)

## Các Loại Địa Điểm Hỗ Trợ

Danh sách có sẵn trong `PlaceType`:
- restaurant, cafe, hospital, pharmacy, hotel
- bank, atm, supermarket, convenience_store
- gas_station, parking, school, university
- library, museum, park, gym
- movie_theater, shopping_mall, police, fire_station
- doctor, dentist

## Xử Lý Lỗi và Best Practices

### Try-Catch Handling
```dart
try {
  final response = await placesService.searchNearby(
    latitude: lat,
    longitude: lng,
    type: PlaceType.restaurant,
  );
  
  if (response == null) {
    print('Không thể lấy dữ liệu');
  } else if (response.results.isEmpty) {
    print('Không tìm thấy địa điểm');
  }
} catch (e) {
  print('Lỗi: $e');
}
```

### Quản Lý Vị Trí
```dart
import 'package:geolocator/geolocator.dart';

Future<Position?> getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Dịch vụ vị trí chưa được bật');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    
    return position;
  } catch (e) {
    print('Lỗi lấy vị trí: $e');
    return null;
  }
}
```

## Billing & Pricing

Theo tài liệu Google:
- **Nearby Search Pro SKU**: $20 per 1000 requests
- Các trường như ADDRESS_COMPONENTS, BUSINESS_STATUS, DISPLAY_NAME sử dụng SKU này
- Các trường khác như RATING, OPENING_HOURS sử dụng "Nearby Search for Business" SKU

Tham khảo: https://developers.google.com/maps/documentation/places/android-sdk/usage-and-billing

## Tối Ưu Hóa Hiệu Năng

### 1. Giới Hạn Trường Yêu Cầu
Chỉ yêu cầu những trường thực sự cần thiết để giảm chi phí.

### 2. Bán Kính Hợp Lý
Không dùng bán kính quá lớn:
```dart
// Good: Tìm trong 1-2km
searchNearby(radius: 1000);

// Avoid: Quá rộng
searchNearby(radius: 50000);
```

### 3. Lọc Loại Trước
Dùng `includedTypes` để lọc, đỡ tải nhiều không cần thiết.

### 4. Caching
Lưu kết quả tìm kiếm để tránh request trùng lặp:
```dart
class PlacesCache {
  static final Map<String, dynamic> _cache = {};
  
  static void save(String key, dynamic value) {
    _cache[key] = value;
  }
  
  static dynamic get(String key) {
    return _cache[key];
  }
}
```

## Troubleshooting

### Lỗi: "API Key is invalid"
- Kiểm tra API Key có đúng không
- Đảm bảo API Key được bật cho Places SDK
- Kiểm tra SHA-1 fingerprint

### Lỗi: "RequestDeniedException"
- Bật Places API trong Google Cloud Console
- Đợi 5-10 phút sau khi bật API

### Lỗi: "Location services are disabled"
- Yêu cầu người dùng bật GPS
- Kiểm tra quyền LOCATION đã được cấp không

### Lỗi: "ZERO_RESULTS"
- Bán kính quá nhỏ
- Vị trí không có kết quả nào
- Kiểm tra loại địa điểm hỗ trợ không

## Tài Liệu Tham Khảo

- [Google Maps Places Android SDK](https://developers.google.com/maps/documentation/places/android-sdk/nearby-search)
- [Google Cloud Console](https://console.cloud.google.com)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Google Places Flutter](https://pub.dev/packages/google_places_flutter)

## Hỗ Trợ Thêm

Nếu gặp vấn đề:
1. Kiểm tra lại API Key
2. Xem console logs để tìm lỗi cụ thể
3. Tham khảo Google Developers documentation
4. Hỏi trên Stack Overflow với tag `google-places-api` và `flutter`
