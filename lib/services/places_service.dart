import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model đơn giản để đại diện cho kết quả tìm kiếm
class PlaceResult {
  final String? placeId;
  final String? name;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingCount;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final bool? openNow;

  PlaceResult({
    this.placeId,
    this.name,
    this.formattedAddress,
    this.rating,
    this.userRatingCount,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.openNow,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;

    return PlaceResult(
      placeId: json['place_id'] as String?,
      name: json['name'] as String?,
      formattedAddress: json['vicinity'] as String? ?? json['formatted_address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['user_ratings_total'] as int?,
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
      openNow: openingHours?['open_now'] as bool?,
    );
  }
}

/// Model để đại diện cho phản hồi tìm kiếm
class SearchNearbyResponse {
  final List<PlaceResult> results;
  final String? nextPageToken;

  SearchNearbyResponse({
    required this.results,
    this.nextPageToken,
  });
}

/// Model để đại diện cho chi tiết địa điểm
class PlaceDetails {
  final String? name;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingCount;
  final String? website;
  final String? internationalPhoneNumber;
  final Map<String, dynamic>? openingHours;
  final double? latitude;
  final double? longitude;

  PlaceDetails({
    this.name,
    this.formattedAddress,
    this.rating,
    this.userRatingCount,
    this.website,
    this.internationalPhoneNumber,
    this.openingHours,
    this.latitude,
    this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    return PlaceDetails(
      name: json['name'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['user_ratings_total'] as int?,
      website: json['website'] as String?,
      internationalPhoneNumber: json['international_phone_number'] as String?,
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
    );
  }
}

class PlacesService {
  final String _apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  PlacesService({required String apiKey}) : _apiKey = apiKey;

  /// Tìm kiếm các địa điểm lân cận
  Future<SearchNearbyResponse?> searchNearby({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String? type,
    String language = 'vi',
    int maxResults = 10,
  }) async {
    try {
      final queryParams = {
        'location': '$latitude,$longitude',
        'radius': '$radius',
        'language': language,
        'key': _apiKey,
      };
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$_baseUrl/nearbysearch/json').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final resultsJson = data['results'] as List<dynamic>? ?? [];
          final results = resultsJson
              .take(maxResults)
              .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
              .toList();

          return SearchNearbyResponse(
            results: results,
            nextPageToken: data['next_page_token'] as String?,
          );
        } else {
          print('Places API error status: $status - ${data['error_message'] ?? ''}');
          return SearchNearbyResponse(results: []);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi tìm kiếm lân cận: $e');
      return null;
    }
  }

  /// Tìm kiếm nhiều loại địa điểm cùng lúc
  Future<List<SearchNearbyResponse>> searchMultipleTypes({
    required double latitude,
    required double longitude,
    int radius = 1000,
    required List<String> types,
  }) async {
    try {
      final results = <SearchNearbyResponse>[];

      for (String type in types) {
        final response = await searchNearby(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          type: type,
        );

        if (response != null) {
          results.add(response);
        }
      }

      return results;
    } catch (e) {
      print('Lỗi khi tìm kiếm nhiều loại: $e');
      return [];
    }
  }

  /// Lấy chi tiết của một địa điểm cụ thể
  Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
    String fields =
        'name,formatted_address,rating,user_ratings_total,opening_hours,website,international_phone_number,geometry',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/details/json').replace(queryParameters: {
        'place_id': placeId,
        'fields': fields,
        'language': 'vi',
        'key': _apiKey,
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          return PlaceDetails.fromJson(result);
        }
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy chi tiết địa điểm: $e');
      return null;
    }
  }

  /// Tìm kiếm địa điểm theo văn bản
  Future<SearchNearbyResponse?> searchByText({
    required String query,
    double? latitude,
    double? longitude,
    String language = 'vi',
  }) async {
    try {
      final queryParams = <String, String>{
        'query': query,
        'language': language,
        'key': _apiKey,
      };
      if (latitude != null && longitude != null) {
        queryParams['location'] = '$latitude,$longitude';
        queryParams['radius'] = '5000';
      }

      final uri = Uri.parse('$_baseUrl/textsearch/json').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final resultsJson = data['results'] as List<dynamic>? ?? [];
          final results = resultsJson
              .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
              .toList();

          return SearchNearbyResponse(
            results: results,
            nextPageToken: data['next_page_token'] as String?,
          );
        }
      }
      return SearchNearbyResponse(results: []);
    } catch (e) {
      print('Lỗi khi tìm kiếm theo văn bản: $e');
      return null;
    }
  }
}

/// Model cho các loại địa điểm phổ biến
class PlaceType {
  static const String restaurant = 'restaurant';
  static const String cafe = 'cafe';
  static const String hospital = 'hospital';
  static const String pharmacy = 'pharmacy';
  static const String hotel = 'hotel';
  static const String bank = 'bank';
  static const String atm = 'atm';
  static const String supermarket = 'supermarket';
  static const String convenience_store = 'convenience_store';
  static const String gas_station = 'gas_station';
  static const String parking = 'parking';
  static const String school = 'school';
  static const String university = 'university';
  static const String library = 'library';
  static const String museum = 'museum';
  static const String park = 'park';
  static const String gym = 'gym';
  static const String movie_theater = 'movie_theater';
  static const String shopping_mall = 'shopping_mall';
  static const String police = 'police';
  static const String fire_station = 'fire_station';
  static const String doctor = 'doctor';
  static const String dentist = 'dentist';

  /// Danh sách tất cả các loại địa điểm
  static const List<String> allTypes = [
    restaurant,
    cafe,
    hospital,
    pharmacy,
    hotel,
    bank,
    atm,
    supermarket,
    convenience_store,
    gas_station,
    parking,
    school,
    university,
    library,
    museum,
    park,
    gym,
    movie_theater,
    shopping_mall,
    police,
    fire_station,
    doctor,
    dentist,
  ];

  /// Lấy tên tiếng Việt của loại địa điểm
  static String getDisplayName(String type) {
    const Map<String, String> displayNames = {
      restaurant: 'Nhà hàng',
      cafe: 'Quán cà phê',
      hospital: 'Bệnh viện',
      pharmacy: 'Nhà thuốc',
      hotel: 'Khách sạn',
      bank: 'Ngân hàng',
      atm: 'ATM',
      supermarket: 'Siêu thị',
      convenience_store: 'Cửa hàng tiện lợi',
      gas_station: 'Trạm xăng',
      parking: 'Bãi đỗ xe',
      school: 'Trường học',
      university: 'Đại học',
      library: 'Thư viện',
      museum: 'Bảo tàng',
      park: 'Công viên',
      gym: 'Phòng tập thể dục',
      movie_theater: 'Rạp chiếu phim',
      shopping_mall: 'Trung tâm mua sắm',
      police: 'Đồn cảnh sát',
      fire_station: 'Trạm cứu hỏa',
      doctor: 'Bác sĩ',
      dentist: 'Nha sĩ',
    };

    return displayNames[type] ?? type;
  }
}
