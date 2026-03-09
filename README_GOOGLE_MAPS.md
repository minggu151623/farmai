# 🗺️ Google Maps Places API - Nearby Search Integration

## 📖 Tổng Quan

Dự án này đã được tích hợp hoàn toàn **Google Maps Places API** với tính năng **Nearby Search** cho ứng dụng Flutter Android của bạn.

Dựa trên tài liệu chính thức: [Google Maps Places Android SDK - Nearby Search](https://developers.google.com/maps/documentation/places/android-sdk/nearby-search?hl=vi)

---

## ✨ Tính Năng

✅ **Tìm kiếm địa điểm lân cận** - Tìm nhà hàng, quán cà phê, bệnh viện, v.v gần vị trí của bạn
✅ **Bản đồ interative** - Hiển thị bản đồ Google Maps với vị trí hiện tại
✅ **Lựa chọn loại địa điểm** - Dropdown với 24+ loại địa điểm
✅ **Điều chỉnh bán kính** - Slider từ 0.1 - 50km
✅ **Hiển thị kết quả** - Danh sách với tên, địa chỉ, rating
✅ **Permission handling** - Tự động xin phép vị trí
✅ **Error handling** - Xử lý lỗi toàn diện

---

## 📁 Files Được Tạo / Cập Nhật

### 1. **Dependencies** ⬆️
```
pubspec.yaml
├── google_places_flutter: ^2.0.8  ← NEW
├── geolocator: ^12.0.0            ← NEW
└── google_maps_flutter: ^2.14.0   (đã có)
```

### 2. **Service Layer** 🔧
```
lib/services/
├── places_service.dart                    ← Service class chính
│   ├── PlacesService               (Main class với 4 methods)
│   ├── PlaceType                   (24+ loại địa điểm)
│   └── PlaceType.getDisplayName()  (Tên tiếng Việt)
│
└── places_service_examples.dart           ← 10+ ví dụ sử dụng
    ├── Tìm kiếm lân cận
    ├── Tìm kiếm nhiều loại
    ├── Lấy chi tiết địa điểm
    ├── Tìm kiếm theo văn bản
    ├── Tích hợp UI
    ├── Quản lý quyền
    ├── Caching
    ├── Tính khoảng cách
    ├── Error handling
    └── ... và nhiều hơn nữa
```

### 3. **UI Screens** 🎨
```
lib/screens/
└── nearby_search_screen.dart              ← Màn hình hoàn chỉnh
    ├── Google Maps hiển thị
    ├── Search control panel
    ├── Results list
    └── Permission & error handling
```

### 4. **Documentation** 📚
```
Project Root/
├── QUICK_START.md                         ← ⭐ Bắt đầu nhanh (5 phút)
├── IMPLEMENTATION_GUIDE.md                ← Step-by-step chi tiết
└── GOOGLE_MAPS_SETUP_GUIDE.md             ← Hướng dẫn đầy đủ

lib/services/
└── places_service_examples.dart           ← Code examples
```

---

## 🚀 Bắt Đầu Nhanh

### 1. Lấy API Key (2 phút)
```
console.cloud.google.com → Enable Maps SDK → Create API Key
```

### 2. Cập Nhật AndroidManifest.xml (1 phút)
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### 3. Chạy Dependencies (2 phút)
```bash
flutter clean && flutter pub get
```

### 4. Sử Dụng trong App (1 phút)
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

**✅ Xong!** Ứng dụng của bạn đã có tính năng tìm kiếm địa điểm lân cận.

---

## 📚 Chi Tiết Files

### PlacesService Class

**Location:** `lib/services/places_service.dart`

**Methods:**
```dart
// Tìm kiếm địa điểm lân cận theo loại
searchNearby({
  required double latitude,
  required double longitude,
  int radius = 1000,        // Mét
  String? type,             // Loại địa điểm
  String language = 'vi',
  int maxResults = 10,
})

// Tìm kiếm nhiều loại cùng lúc
searchMultipleTypes({
  required double latitude,
  required double longitude,
  int radius = 1000,
  required List<String> types,
})

// Lấy chi tiết địa điểm
getPlaceDetails({
  required String placeId,
  String fields = '...',  // Các trường cần lấy
})

// Tìm kiếm theo văn bản
searchByText({
  required String query,
  double? latitude,
  double? longitude,
  String language = 'vi',
})
```

### PlaceType Constants

```dart
PlaceType.restaurant          // Nhà hàng
PlaceType.cafe               // Quán cà phê
PlaceType.hospital           // Bệnh viện
PlaceType.pharmacy           // Nhà thuốc
PlaceType.hotel              // Khách sạn
PlaceType.bank               // Ngân hàng
PlaceType.atm                // ATM
PlaceType.supermarket        // Siêu thị
PlaceType.convenience_store  // Cửa hàng tiện lợi
PlaceType.gas_station        // Trạm xăng
PlaceType.parking            // Bãi đỗ xe
PlaceType.school             // Trường học
PlaceType.university         // Đại học
PlaceType.library            // Thư viện
PlaceType.museum             // Bảo tàng
PlaceType.park               // Công viên
PlaceType.gym                // Phòng tập
PlaceType.movie_theater      // Rạp chiếu phim
PlaceType.shopping_mall      // Trung tâm mua sắm
PlaceType.police             // Đồn cảnh sát
PlaceType.fire_station       // Trạm cứu hỏa
PlaceType.doctor             // Bác sĩ
PlaceType.dentist            // Nha sĩ
```

### NearbySearchScreen

**Location:** `lib/screens/nearby_search_screen.dart`

**Features:**
- Google Maps với vị trí hiện tại
- Lựa chọn loại địa điểm (Dropdown)
- Slider điều chỉnh bán kính (100m - 50km)
- Hiệu ứng loading
- Danh sách kết quả với:
  - Tên địa điểm
  - Địa chỉ đầy đủ
  - Đánh giá ⭐
- Error handling

---

## 🔐 Cấu Hình Bảo Mật

### Android Permissions Already Set

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### Request Runtime Permissions

```dart
final status = await Permission.location.request();
if (status.isGranted) {
  // Tiếp tục...
}
```

---

## 💡 Ví Dụ Sử Dụng

### Ví Dụ 1: Tìm Kiếm Đơn Giản

```dart
import 'services/places_service.dart';
import 'package:geolocator/geolocator.dart';

final placesService = PlacesService(apiKey: 'YOUR_KEY');

final position = await Geolocator.getCurrentPosition();

final results = await placesService.searchNearby(
  latitude: position.latitude,
  longitude: position.longitude,
  type: PlaceType.restaurant,
  radius: 1000,
);

for (var place in results?.results ?? []) {
  print('${place.name} - Địa chỉ: ${place.formatted_address}');
}
```

### Ví Dụ 2: Tìm Kiếm Nhiều Loại

```dart
final results = await placesService.searchMultipleTypes(
  latitude: 21.0285,
  longitude: 105.8542,
  radius: 2000,
  types: [PlaceType.restaurant, PlaceType.cafe, PlaceType.hospital],
);
```

### Ví Dụ 3: Lấy Chi Tiết Địa Điểm

```dart
final details = await placesService.getPlaceDetails(
  placeId: 'ChIJLcMPW7ZAc2gR...',
  fields: 'name,rating,website,opening_hours',
);

print('Điểm số: ${details?.rating}');
print('Website: ${details?.website}');
```

### Ví Dụ 4: Sử Dụng NearbySearchScreen

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

---

## 📋 API Requirements (Theo Google)

### Yêu Cầu Bắt Buộc

1. **Field List** - Phải chỉ định ít nhất 1 trường dữ liệu
2. **Location Restriction** - Vĩ độ, kinh độ, bán kính (0 < r ≤ 50,000m)

### Thông Số Tùy Chọn

- `includedTypes` - Chỉ loại nhất định
- `excludedTypes` - Loại trừ các loại
- `maxResultCount` - Số kết quả tối đa (1-20)
- `rankPreference` - POPULARITY hoặc DISTANCE
- `regionCode` - Mã khu vực (VN cho Việt Nam)

---

## 💰 Billing

Theo Google Places API Pricing:
- **Nearby Search Pro SKU**: $20 per 1000 calls
- Một số fields sử dụng "Nearby Search for Business" SKU

Tham khảo: [Google Maps Billing](https://developers.google.com/maps/documentation/places/android-sdk/usage-and-billing)

---

## 🔍 Troubleshooting

| Vấn Đề | Giải Pháp |
|--------|----------|
| API Key invalid | Kiểm tra key, bật APIs, bổ sung SHA-1 |
| Permission denied | Cho phép quyền vị trí trong Device Settings |
| No results | Bán kính quá nhỏ hoặc loại không tồn tại |
| Location services disabled | Bật GPS trong Device Settings |
| ZERO_RESULTS | Thử bán kính lớn hơn, kiểm tra loại |

---

## 📖 Tài Liệu

### Trong Dự Án
1. **[QUICK_START.md](QUICK_START.md)** - Bắt đầu nhanh trong 5 phút ⭐
2. **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Hướng dẫn chi tiết step-by-step
3. **[GOOGLE_MAPS_SETUP_GUIDE.md](GOOGLE_MAPS_SETUP_GUIDE.md)** - Hướng dẫn đầy đủ
4. **[lib/services/places_service_examples.dart](lib/services/places_service_examples.dart)** - 10+ ví dụ code

### Ngoài
- [Google Places Android SDK](https://developers.google.com/maps/documentation/places/android-sdk)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

## 🎯 Next Steps

1. ✅ Lấy API Key từ Google Cloud Console
2. ✅ Cập nhật AndroidManifest.xml với API Key
3. ✅ Chạy `flutter pub get`
4. ✅ Test trên device thực
5. ⬜ Thêm features:
   - Favorites/Bookmarks
   - User reviews
   - Photos gallery
   - Directions
   - Share location

---

## 🆘 Hỗ Trợ Thêm

Nếu gặp vấn đề:
1. Xem lại các guide docs (QUICK_START → IMPLEMENTATION_GUIDE)
2. Kiểm tra console logs
3. Xem ví dụ trong `places_service_examples.dart`
4. Tham khảo Google Developers documentation

---

## 📝 Tóm Tắt

| Item | Status |
|------|--------|
| Dependencies | ✅ Cập nhật |
| PlacesService | ✅ Tạo |
| NearbySearchScreen | ✅ Tạo |
| Documentation | ✅ Đầy đủ |
| Examples | ✅ 10+ ví dụ |
| Android Config | ✅ OK |
| API Integration | ✅ Sẵn sàng |

**Bạn đã sẵn sàng để sử dụng!** 🚀

---

**Tạo bởi:** GitHub Copilot  
**Ngày:** 2026-03-03  
**Phiên bản:** 1.0
