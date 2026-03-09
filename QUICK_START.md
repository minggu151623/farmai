# ⚡ Quick Start - Google Maps Nearby Search

## 5 Phút Để Bắt Đầu

### Bước 1: Lấy API Key (2 phút)

```
1. Truy cập: https://console.cloud.google.com
2. Tạo project → Enable "Maps SDK for Android" + "Places API"
3. Credentials → Create API Key
4. Copy API Key
```

### Bước 2: Cập Nhật AndroidManifest.xml (1 phút)

**File: `android/app/src/main/AndroidManifest.xml`**

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### Bước 3: Chạy Lệnh (2 phút)

```bash
flutter clean
flutter pub get
flutter run
```

---

## Sử Dụng Ngay

### Cách 1: Sử Dụng Màn Hình Có Sẵn (Nhanh Nhất)

```dart
import 'screens/nearby_search_screen.dart';

// Trong bất kỳ nơi nào
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NearbySearchScreen(
      apiKey: 'YOUR_API_KEY_HERE',
    ),
  ),
);
```

### Cách 2: Sử Dụng PlacesService Thủ Công

```dart
import 'services/places_service.dart';

final placesService = PlacesService(apiKey: 'YOUR_API_KEY_HERE');

// Tìm nhà hàng lân cận
final results = await placesService.searchNearby(
  latitude: 21.0285,
  longitude: 105.8542,
  type: PlaceType.restaurant,
  radius: 1000,
);

for (var place in results?.results ?? []) {
  print('${place.name} - ⭐ ${place.rating}');
}
```

---

## Các Loại Địa Điểm Sẵn Có

```dart
PlaceType.restaurant      // Nhà hàng
PlaceType.cafe           // Quán cà phê
PlaceType.hospital       // Bệnh viện
PlaceType.pharmacy       // Nhà thuốc
PlaceType.hotel          // Khách sạn
PlaceType.supermarket    // Siêu thị
PlaceType.bank           // Ngân hàng
PlaceType.park           // Công viên
PlaceType.school         // Trường học
```

---

## Các Thông Số

| Tham Số | Loại | Mô Tả | Mặc Định |
|---------|-----|--------|---------|
| `latitude` | double | Vĩ độ | **Bắt buộc** |
| `longitude` | double | Kinh độ | **Bắt buộc** |
| `radius` | int | Bán kính (mét) | 1000 |
| `type` | String | Loại địa điểm | none |
| `maxResults` | int | Kết quả tối đa | 10 |
| `language` | String | Ngôn ngữ | 'vi' |

---

## Fix Lỗi Nhanh

| Lỗi | Giải Pháp |
|-----|----------|
| API Key invalid | Kiểm tra lại key, bật Maps SDK |
| Permission denied | Cho phép quyền vị trí trong Settings |
| No results | Bán kính quá nhỏ hoặc loại không tồn tại |
| LocationServices disabled | Bật GPS trong Settings |

---

## Ví Dụ Đơn Giản (10 dòng code)

```dart
import 'services/places_service.dart';
import 'package:geolocator/geolocator.dart';

// 1. Khởi tạo
final places = PlacesService(apiKey: 'YOUR_KEY');

// 2. Lấy vị trí
final pos = await Geolocator.getCurrentPosition();

// 3. Tìm kiếm
final result = await places.searchNearby(
  latitude: pos.latitude,
  longitude: pos.longitude,
  type: PlaceType.restaurant,
);

// 4. Xử lý
result?.results.forEach((p) => print(p.name));
```

---

## Files Đã Tạo

```
lib/
├── services/
│   ├── places_service.dart             ← Main Service Class
│   └── places_service_examples.dart    ← Ví dụ sử dụng
├── screens/
│   └── nearby_search_screen.dart       ← UI hoàn chỉnh
└── main.dart

docs/
├── GOOGLE_MAPS_SETUP_GUIDE.md          ← Hướng dẫn chi tiết
├── IMPLEMENTATION_GUIDE.md             ← Step-by-step
└── QUICK_START.md                      ← Này!
```

---

## Cập Nhật pubspec.yaml

```yaml
dependencies:
  google_maps_flutter: ^2.14.0
  google_places_flutter: ^2.0.8
  geolocator: ^12.0.0
  permission_handler: ^12.0.1  # Đã có
```

---

## Checklist

- [ ] Tạo Google Cloud Project
- [ ] Bật Maps SDK for Android
- [ ] Bật Places API
- [ ] Tạo API Key
- [ ] Cập nhật AndroidManifest.xml
- [ ] Chạy `flutter pub get`
- [ ] Chạy `flutter clean`
- [ ] Test trên device

---

## Các Bước Tiếp Theo

1. **Thêm vào Main App**
   ```dart
   // main.dart
   import 'screens/nearby_search_screen.dart';
   ```

2. **Tạo Favorites Screen**
   ```dart
   // Lưu địa điểm yêu thích vào SharedPreferences
   ```

3. **Thêm Reviews**
   ```dart
   // Hiển thị user reviews từ Google Places
   ```

4. **Tối Ưu Caching**
   ```dart
   // Cache kết quả để giảm API calls
   ```

---

## Hỗ Trợ

**Docs:**
- [setup_guide](GOOGLE_MAPS_SETUP_GUIDE.md)
- [implementation](IMPLEMENTATION_GUIDE.md)
- [examples](lib/services/places_service_examples.dart)

**Lỗi Common:**
```
❌ API Key invalid
✅ → Kiểm tra key, bật APIs, đợi 10 phút

❌ Permission denied  
✅ → Vào Settings → Location → Always

❌ ZERO_RESULTS
✅ → Bán kính nhỏ, kiểm tra loại địa điểm

❌ No internet
✅ → Bật internet, kiểm tra WiFi/Data
```

---

**Sẵn sàng? Bắt đầu từ `IMPLEMENTATION_GUIDE.md` để chi tiết hơn!** 🚀
