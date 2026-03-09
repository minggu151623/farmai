# Hướng Dẫn Tích Hợp Google Maps Nearby Search - Step by Step

## 📋 Lộ Trình Triển Khai

### Giai Đoạn 1: Thiết Lập Ban Đầu (1-2 giờ)

#### Bước 1.1: Tạo Google Cloud Project
```
1. Truy cập https://console.cloud.google.com
2. Tạo project mới (hoặc chọn project hiện có)
3. Bật các API:
   - Maps SDK for Android
   - Places API
   - Maps JavaScript API (nếu cần Web)
```

#### Bước 1.2: Tạo API Key
```
1. Credentials → Create Credentials → API Key
2. Sao chép API Key
3. Giới hạn cho Android (thêm SHA-1 fingerprint)
```

#### Bước 1.3: Lấy SHA-1 Fingerprint

**Cách 1: Sử dụng keytool**
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

**Cách 2: Sử dụng Gradle**
```bash
cd android
./gradlew signingReport
```

#### Bước 1.4: Cập Nhật AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Thay thế `YOUR_API_KEY_HERE` bằng key bạn vừa nhận:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### Giai Đoạn 2: Cài Đặt Dependencies (30-45 phút)

#### Bước 2.1: Cập Nhật pubspec.yaml

```bash
cd your_project
flutter pub get
```

**Dependencies đã tự động được thêm:**
- google_maps_flutter: ^2.14.0
- google_places_flutter: ^2.0.8
- geolocator: ^12.0.0

#### Bước 2.2: Xác Nhận Installation

```bash
flutter doctor
flutter pub get
flutter packages get
```

### Giai Đoạn 3: Cấu Hình Android (15 phút)

#### Bước 3.1: Kiểm Tra AndroidManifest.xml

Đảm bảo có các permissions này:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

#### Bước 3.2: Cấu Hình Gradle

**File: `android/build.gradle.kts`**
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

**File: `android/app/build.gradle.kts`**
```kotlin
android {
    compileSdk = flutter.compileSdkVersion
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

### Giai Đoạn 4: Cấu Hình Flutter Code (1-2 giờ)

#### Bước 4.1: Kích Hoạt Permission (iOS & Android)

**File: `lib/main.dart` (trong initState)**

```dart
Future<void> _requestPermissions() async {
  final status = await Permission.location.request();
  
  if (status.isGranted) {
    print('Location permission granted');
  } else if (status.isDenied) {
    print('Location permission denied');
  }
}
```

#### Bước 4.2: Thêm NearbySearchScreen vào Navigation

**Option A: Thêm button vào màn hình hiện tại**

```dart
import 'screens/nearby_search_screen.dart';

// Trong build() method
FloatingActionButton(
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
  child: const Icon(Icons.location_on),
)
```

**Option B: Thêm vào Routes**

```dart
// File: lib/main.dart

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      routes: {
        '/': (context) => const HomeScreen(),
        '/nearby-search': (context) => NearbySearchScreen(
          apiKey: 'YOUR_API_KEY_HERE',
        ),
      },
      home: const SplashScreen(),
    );
  }
}

// Gọi từ bất kỳ nơi nào:
Navigator.pushNamed(context, '/nearby-search');
```

#### Bước 4.3: Sử Dụng PlacesService cho Custom UI

```dart
import 'services/places_service.dart';

class CustomPlacesWidget extends StatefulWidget {
  @override
  State<CustomPlacesWidget> createState() => _CustomPlacesWidgetState();
}

class _CustomPlacesWidgetState extends State<CustomPlacesWidget> {
  late PlacesService _placesService;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(
      apiKey: 'YOUR_API_KEY_HERE',
    );
  }

  Future<void> _search() async {
    final Position position = await Geolocator.getCurrentPosition();
    
    final response = await _placesService.searchNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radius: 1000,
      type: PlaceType.restaurant,
    );

    if (response != null) {
      // Xử lý kết quả
      setState(() {
        // Update UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _search,
          child: const Text('Tìm kiếm'),
        ),
      ],
    );
  }
}
```

### Giai Đoạn 5: Testing & Debugging (1-2 giờ)

#### Bước 5.1: Kiểm Tra Cơ Bản

```bash
# Xóa cache build cũ
flutter clean

# Cài package lại
flutter pub get

# Build lại dự án
flutter pub upgrade
```

#### Bước 5.2: Test trên Device

```bash
# Chạy app trên device
flutter run

# Hoặc chạy release build
flutter run --release
```

#### Bước 5.3: Debugging Errors

**Nếu có lỗi API Key:**
```bash
# Kiểm tra logs
flutter logs

# Tìm SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore
```

**Nếu lỗi Permission:**
```
Kiểm tra:
- AndroidManifest.xml có permission chưa
- Device có bật GPS không
- Cho phép quyền trong Settings
```

### Giai Đoạn 6: Triển Khai Production (1 giờ)

#### Bước 6.1: Tạo Signed APK

```bash
# Build signed APK
flutter build apk --split-per-abi

# Build App Bundle
flutter build appbundle
```

#### Bước 6.2: Tạo API Key cho Signed APK

```bash
# Lấy SHA-1 của signing key
keytool -list -v -keystore path/to/your/keystore.jks
```

#### Bước 6.3: Cập Nhật AndroidManifest.xml với Key mới

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_PRODUCTION_API_KEY"/>
```

---

## 🔧 Tìm Hiểu Chi Tiết

### PlacesService API

#### Constructor
```dart
PlacesService(required String apiKey)
```

#### Methods

**1. searchNearby()**
```dart
Future<SearchNearbyResponse?> searchNearby({
  required double latitude,
  required double longitude,
  int radius = 1000,
  String? type,
  String language = 'vi',
  int maxResults = 10,
})
```

**2. searchMultipleTypes()**
```dart
Future<List<SearchNearbyResponse>> searchMultipleTypes({
  required double latitude,
  required double longitude,
  int radius = 1000,
  required List<String> types,
})
```

**3. getPlaceDetails()**
```dart
Future<PlaceDetails?> getPlaceDetails({
  required String placeId,
  String fields = '...',
})
```

**4. searchByText()**
```dart
Future<SearchNearbyResponse?> searchByText({
  required String query,
  double? latitude,
  double? longitude,
  String language = 'vi',
})
```

### NearbySearchScreen Features

- ✅ Hiển thị bản đồ Google Maps
- ✅ Lựa chọn loại địa điểm
- ✅ Điều chỉnh bán kính tìm kiếm
- ✅ Hiển thị kết quả dạng danh sách
- ✅ Hiển thị rating và địa chỉ

---

## 📱 Sử Dụng Dari Ứng Dụng

### Flow Làm Việc Toàn Bộ

```
1. User mở app
   ↓
2. User nhấp button "Tìm Kiếm Địa Điểm"
   ↓
3. NearbySearchScreen được hiển thị
   ↓
4. App yêu cầu quyền vị trí
   ↓
5. App lấy vị trí hiện tại
   ↓
6. Bản đồ hiển thị vị trí hiện tại
   ↓
7. User chọn loại địa điểm (ví dụ: restaurant)
   ↓
8. User điều chỉnh bán kính (ví dụ: 2km)
   ↓
9. User nhấp "Tìm Kiếm"
   ↓
10. PlacesService gọi Google Places API
    ↓
11. Kết quả được hiển thị
    ↓
12. User có thể xem chi tiết từng địa điểm
```

### Example Screens Cần Tạo

Bạn có thể tạo các màn hình khác:

**1. Restaurant List Screen**
```dart
class RestaurantListScreen extends StatefulWidget {
  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  // Sử dụng PlacesService để tìm nhà hàng
}
```

**2. Place Detail Screen**
```dart
class PlaceDetailScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailScreen({required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  // Sử dụng getPlaceDetails() để lấy thông tin chi tiết
}
```

---

## 🔐 Bảo Mật API Key

### Best Practices

**❌ KHÔNG LÀMÂ**
```dart
// Không hardcode API key trong code
const String API_KEY = 'AIzaSyAtiBTEKiBsqUs0nr0EIFsJgbwHPlG4Vq4';
```

**✅ NÊN LÀMÂ**
```dart
// 1. Sử dụng Environment Variables
import 'dart:io';

final apiKey = Platform.environment['GOOGLE_MAPS_API_KEY'] ?? '';

// 2. Sử dụng flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

// 3. Sử dụng Firebase Remote Config
```

### Setup Environment Variables

**File: `.env`**
```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

**File: `pubspec.yaml`**
```yaml
dependencies:
  flutter_dotenv: ^5.0.2
```

**File: `lib/main.dart`**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}
```

---

## 🐛 Troubleshooting Common Issues

### 1. "API Key is invalid"

**Nguyên nhân:**
- API Key sai
- Loại API Key không đúng
- Kiểm tra không đúng

**Giải pháp:**
```
1. Kiểm tra API Key trong Google Cloud Console
2. Đảm bảo bật Maps SDK for Android
3. Đợi 5-10 phút sau khi tạo key
4. Thêm SHA-1 fingerprint vào key restrictions
```

### 2. "Maps SDK not initialized"

**Nguyên nhân:**
- Chưa cấu hình maps SDK

**Giải pháp:**
```dart
// Thêm vào main.dart
void main() {
  // Initialize maps SDK nếu cần
  runApp(const MyApp());
}
```

### 3. "Permission denied"

**Nguyên nhân:**
- Chưa có quyền vị trí

**Giải pháp:**
```dart
final status = await Permission.location.request();
if (status.isGranted) {
  // Tiếp tục
}
```

### 4. "LocationServiceDisabledException"

**Nguyên nhân:**
- Dịch vụ vị trí không được bật

**Giải pháp:**
```dart
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  await Geolocator.openLocationSettings();
}
```

---

## 📊 Monitoring & Analytics

### Theo Dõi Sử Dụng API

```dart
class PlacesAnalytics {
  static int searchCount = 0;
  static int detailsCount = 0;
  
  static void logSearch() {
    searchCount++;
    print('Tổng tìm kiếm: $searchCount');
  }
  
  static void logDetails() {
    detailsCount++;
    print('Tổng chi tiết: $detailsCount');
  }
}
```

### Track Errors

```dart
try {
  final response = await placesService.searchNearby(...);
} catch (e) {
  // Log error
  print('Error: $e');
  // Gửi tới analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'places_api_error',
    parameters: {'error': e.toString()},
  );
}
```

---

## 🚀 Next Steps

1. ✅ Thiết lập API Key
2. ✅ Cài đặt dependencies
3. ✅ Cấu hình Android
4. ✅ Test trên device
5. ⬜ Tối ưu hiệu năng (caching, pagination)
6. ⬜ Thêm features (favorites, reviews)
7. ⬜ Triển khai production

---

## 📚 Tài Liệu Tham Khảo

- [Google Places Android SDK](https://developers.google.com/maps/documentation/places/android-sdk)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Permission Handler](https://pub.dev/packages/permission_handler)

---

**Nếu gặp vấn đề, kiểm tra:**
1. ✓ API Key có đúng không
2. ✓ SHA-1 fingerprint có khớp không  
3. ✓ AndroidManifest.xml có cấu hình không
4. ✓ Dependencies đã install không
5. ✓ Quyền vị trí đã grant không
