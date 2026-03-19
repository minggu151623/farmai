import 'dart:io';

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DiagnosisResult {
  final String label;
  final String plantName;
  final String diseaseName;
  final double confidence;
  final bool isHealthy;

  const DiagnosisResult({
    required this.label,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
  });
}

class PlantDiseaseService {
  static const String _modelPath = 'assets/ml/plant_disease_model.tflite';
  static const String _labelsPath = 'assets/ml/labels.txt';
  static const int _inputSize = 160;

  Interpreter? _interpreter;
  List<String> _labels = [];

  static final PlantDiseaseService _instance = PlantDiseaseService._internal();
  factory PlantDiseaseService() => _instance;
  PlantDiseaseService._internal();

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> initialize() async {
    try {
      await _loadModel();
      await _loadLabels();
    } catch (e) {
      // Model will be loaded lazily on first classify() call
    }
  }

  Future<void> _loadModel() async {
    final modelData = await rootBundle.load(_modelPath);
    _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());
  }

  Future<void> _loadLabels() async {
    final raw = await rootBundle.loadString(_labelsPath);
    _labels =
        raw.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
      // Labels file format: "0 Apple___Apple_scab"
      // Split on FIRST space only to preserve spaces in disease names
      final spaceIdx = line.indexOf(' ');
      if (spaceIdx > 0) {
        return line.substring(spaceIdx + 1);
      }
      return line;
    }).toList();
    print('[TFLite] Loaded ${_labels.length} labels: $_labels');
  }

  /// Get a list of unique plant names from the labels file
  Future<List<String>> getUniquePlants() async {
    if (!isReady) {
      await initialize();
    }
    final Set<String> uniquePlants = {};
    for (final label in _labels) {
      final parts = label.split('___');
      if (parts.isNotEmpty) {
        final plantName = parts[0].replaceAll('_', ' ');
        uniquePlants.add(plantName);
      }
    }
    return uniquePlants.toList()..sort();
  }

  /// Classify an image for a specific plant (used in Diagnose Screen)
  Future<DiagnosisResult> classify(String imagePath, String selectedPlant) async {
    if (!isReady) {
      await initialize();
      if (!isReady) throw Exception('Service not initialized');
    }

    final probabilities = await _runInference(imagePath);

    // Filter by selected plant
    int maxIdx = -1;
    double maxProb = -1.0;

    final normalizedSelected = selectedPlant.replaceAll(' ', '_');
    print('[TFLite] Looking for plant: "$normalizedSelected"');

    for (int i = 0; i < probabilities.length; i++) {
      final label = _labels[i];
      if (label.startsWith('${normalizedSelected}___') || label == normalizedSelected) {
        print('[TFLite] MATCH [$i]: $label = ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIdx = i;
        }
      }
    }

    if (maxIdx == -1) {
       return DiagnosisResult(
         label: '${selectedPlant}___Unknown',
         plantName: selectedPlant,
         diseaseName: 'Không xác định',
         confidence: 0.0,
         isHealthy: false,
       );
    }

    final label = _labels[maxIdx];
    final parsed = _parseLabel(label);
    print('[TFLite] Best match: $label (${(maxProb * 100).toStringAsFixed(2)}%)');

    return DiagnosisResult(
      label: label,
      plantName: parsed['plant']!,
      diseaseName: parsed['disease']!,
      confidence: maxProb * 100,
      isHealthy: label.toLowerCase().contains('healthy'),
    );
  }

  /// Classify an image without pre-selecting a plant (used in Chat)
  /// Returns a DiagnosisResult with the best match across ALL labels
  Future<DiagnosisResult> classifyForChat(String imagePath) async {
    if (!isReady) {
      await initialize();
      if (!isReady) throw Exception('Service not initialized');
    }

    final probabilities = await _runInference(imagePath);

    // Find overall best match
    int maxIdx = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIdx = i;
      }
    }

    final label = _labels[maxIdx];
    final parsed = _parseLabel(label);
    print('[TFLite-Chat] Best: $label (${(maxProb * 100).toStringAsFixed(2)}%)');

    return DiagnosisResult(
      label: label,
      plantName: parsed['plant']!,
      diseaseName: parsed['disease']!,
      confidence: maxProb * 100,
      isHealthy: label.toLowerCase().contains('healthy'),
    );
  }

  /// Core inference logic — returns softmaxed probabilities
  Future<List<double>> _runInference(String imagePath) async {
    final inputTensorInfo = _interpreter!.getInputTensor(0);
    final outputTensorInfo = _interpreter!.getOutputTensor(0);
    print('[TFLite] Input: shape=${inputTensorInfo.shape}, type=${inputTensorInfo.type}');
    print('[TFLite] Output: shape=${outputTensorInfo.shape}, type=${outputTensorInfo.type}');

    final imageBytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Cannot decode image');

    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final rgbBytes = resized.getBytes(order: img.ChannelOrder.rgb);

    // MobileNetV2 preprocessing:
    // User mentioned "thay vì /255 thì nhân với 255", meaning the model expects [0, 255] 
    // instead of [0, 1] normalized values. rgbBytes is already [0, 255].
    final input = Float32List(_inputSize * _inputSize * 3);
    for (int i = 0; i < rgbBytes.length && i < input.length; i++) {
      input[i] = rgbBytes[i].toDouble();
    }

    print('[TFLite] Input pixel samples (after normalization): ${input.sublist(0, 6)}');

    final inputTensor = input.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(inputTensor, output);

    // The output is ALREADY SOFTMAXED by the model (probabilities sum to ~1.0)
    final probabilities = (output[0] as List<double>);

    // Debug: print raw output range to ensure it's between [0, 1]
    final rawMin = probabilities.reduce((a, b) => a < b ? a : b);
    final rawMax = probabilities.reduce((a, b) => a > b ? a : b);
    print('[TFLite] Output range: min=$rawMin, max=$rawMax');

    // Debug: print top 5
    final indexed = probabilities.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (int i = 0; i < 5 && i < indexed.length; i++) {
      final e = indexed[i];
      final lbl = e.key < _labels.length ? _labels[e.key] : '?';
      print('[TFLite] Top-${i + 1}: $lbl (${(e.value * 100).toStringAsFixed(2)}%)');
    }

    return probabilities;
  }

  Map<String, String> _parseLabel(String label) {
    final parts = label.split('___');
    final plant = _formatName(parts[0]);
    final disease = parts.length > 1 ? _formatName(parts[1]) : 'Unknown';
    return {'plant': plant, 'disease': disease};
  }

  String _formatName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .replaceAll('  ', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  void dispose() {
    _interpreter?.close();
  }

  // --- Static disease info database ---
  static Map<String, String> getOverview(String label) {
    return _diseaseInfo[label] ?? _defaultInfo;
  }

  static const Map<String, String> _defaultInfo = {
    'overview': 'Chưa có thông tin chi tiết về bệnh này trong cơ sở dữ liệu.',
    'cause': 'Đang cập nhật.',
    'signs': 'Đang cập nhật.',
    'solutions': 'Tham khảo ý kiến chuyên gia nông nghiệp.',
  };

  static const Map<String, Map<String, String>> _diseaseInfo = {
    'Apple___Apple_scab': {
      'overview':
          'Bệnh ghẻ táo do nấm Venturia inaequalis gây ra, phổ biến ở vùng ẩm ướt.',
      'cause':
          'Nấm Venturia inaequalis lây lan qua bào tử trong điều kiện ẩm và mát.',
      'signs': 'Vết đốm xám-nâu trên lá, quả bị nứt và biến dạng.',
      'solutions': 'Phun thuốc trừ nấm,Cắt tỉa cành bệnh,Dọn lá rụng quanh gốc',
    },
    'Apple___Black_rot': {
      'overview': 'Bệnh thối đen táo do nấm Botryosphaeria obtusa.',
      'cause': 'Nấm xâm nhập qua vết thương trên vỏ cây trong thời tiết ấm ẩm.',
      'signs': 'Vết thối đen trên quả, lá có đốm tím viền nâu.',
      'solutions': 'Loại bỏ quả bệnh,Phun thuốc đồng,Cắt tỉa cành chết',
    },
    'Apple___Cedar_apple_rust': {
      'overview':
          'Bệnh rỉ sắt táo do nấm Gymnosporangium juniperi-virginianae.',
      'cause': 'Nấm cần cả cây táo và cây tùng bách để hoàn thành vòng đời.',
      'signs': 'Đốm vàng cam trên lá, mặt dưới lá có mụn nhọn.',
      'solutions':
          'Loại bỏ cây tùng bách gần vườn,Phun thuốc trừ nấm vào mùa xuân,Trồng giống kháng bệnh',
    },
    'Apple___healthy': {
      'overview': 'Cây táo khỏe mạnh, không phát hiện bệnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, không có đốm hay biến dạng.',
      'solutions': 'Tiếp tục chăm sóc bình thường',
    },
    'Blueberry___healthy': {
      'overview': 'Cây việt quất khỏe mạnh, không có dấu hiệu bệnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, quả phát triển bình thường.',
      'solutions': 'Duy trì chế độ chăm sóc hiện tại',
    },
    'Cherry_(including_sour)___Powdery_mildew': {
      'overview': 'Bệnh phấn trắng trên cherry do nấm Podosphaera clandestina.',
      'cause': 'Nấm phát triển mạnh trong điều kiện ấm, khô, thiếu ánh nắng.',
      'signs': 'Lớp bột trắng trên lá non, lá cuộn và biến dạng.',
      'solutions':
          'Phun thuốc trừ nấm lưu huỳnh,Tăng lưu thông gió,Cắt tỉa cành rậm',
    },
    'Cherry_(including_sour)___healthy': {
      'overview': 'Cây cherry khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh bóng, không có đốm.',
      'solutions': 'Duy trì chăm sóc bình thường',
    },
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': {
      'overview': 'Bệnh đốm xám lá ngô do nấm Cercospora zeae-maydis.',
      'cause':
          'Nấm sống sót trên tàn dư cây trồng, phát tán trong điều kiện ẩm.',
      'signs': 'Vết đốm chữ nhật, xám, chạy song song gân lá.',
      'solutions':
          'Luân canh cây trồng,Cày vùi tàn dư,Trồng giống kháng bệnh,Phun fungicide',
    },
    'Corn_(maize)___Common_rust_': {
      'overview': 'Bệnh rỉ sắt ngô do nấm Puccinia sorghi.',
      'cause': 'Bào tử nấm theo gió từ vùng nhiệt đới, phát triển ở 15-25°C.',
      'signs': 'Mụn nhỏ màu nâu đỏ trên cả hai mặt lá.',
      'solutions':
          'Trồng giống kháng bệnh,Phun thuốc trừ nấm sớm,Trồng đúng thời vụ',
    },
    'Corn_(maize)___Northern_Leaf_Blight': {
      'overview': 'Bệnh cháy lá phương bắc ngô do nấm Exserohilum turcicum.',
      'cause': 'Nấm lây lan qua bào tử trong điều kiện mát ẩm.',
      'signs': 'Vết cháy hình điếu thuốc, dài 3-15cm, xám xanh.',
      'solutions':
          'Luân canh cây trồng,Phun fungicide phòng ngừa,Trồng giống kháng',
    },
    'Corn_(maize)___healthy': {
      'overview': 'Cây ngô khỏe mạnh, phát triển tốt.',
      'cause': 'Không có.',
      'signs': 'Lá xanh đậm, thân cứng cáp.',
      'solutions': 'Duy trì bón phân và tưới hợp lý',
    },
    'Grape___Black_rot': {
      'overview': 'Bệnh thối đen nho do nấm Guignardia bidwellii.',
      'cause': 'Nấm sống trên quả và lá mốc, phát tán trong mưa ấm.',
      'signs': 'Đốm nâu trên lá, quả khô đen và nhăn nheo.',
      'solutions':
          'Loại bỏ quả bệnh và tàn dư,Phun fungicide định kỳ,Tỉa cành thông thoáng',
    },
    'Grape___Esca_(Black_Measles)': {
      'overview': 'Bệnh sởi đen nho (Esca) do phức hợp nấm gây ra.',
      'cause': 'Nhiều loại nấm xâm nhập qua vết cắt tỉa.',
      'signs': 'Sọc vàng nâu giữa các gân lá, quả có đốm tím.',
      'solutions':
          'Cắt bỏ phần gỗ bệnh,Bảo vệ vết cắt tỉa,Không có thuốc đặc trị hiệu quả',
    },
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': {
      'overview': 'Bệnh cháy lá nho do nấm Pseudocercospora vitis.',
      'cause': 'Nấm phát triển trong điều kiện nóng ẩm.',
      'signs': 'Đốm nâu đỏ với viền vàng trên lá, lá rụng sớm.',
      'solutions': 'Phun Bordeaux,Cắt tỉa tạo thông thoáng,Thu gom lá bệnh',
    },
    'Grape___healthy': {
      'overview': 'Cây nho khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, quả phát triển đều.',
      'solutions': 'Tiếp tục chăm sóc và phòng bệnh định kỳ',
    },
    'Orange___Haunglongbing_(Citrus_greening)': {
      'overview':
          'Bệnh vàng lá greening cam do vi khuẩn Candidatus Liberibacter.',
      'cause': 'Vi khuẩn lây truyền qua rầy chổng cánh (Diaphorina citri).',
      'signs': 'Lá vàng không đối xứng, quả nhỏ lệch, vị đắng.',
      'solutions':
          'Diệt rầy chổng cánh,Nhổ bỏ cây bệnh nặng,Trồng cây giống sạch bệnh,Kiểm tra định kỳ',
    },
    'Peach___Bacterial_spot': {
      'overview': 'Bệnh đốm vi khuẩn đào do Xanthomonas arboricola.',
      'cause': 'Vi khuẩn lây lan qua mưa gió, xâm nhập qua lỗ khí.',
      'signs': 'Đốm nước trên lá, vết loét trên quả và cành.',
      'solutions': 'Phun thuốc đồng,Trồng giống kháng,Tránh tưới phun mưa',
    },
    'Peach___healthy': {
      'overview': 'Cây đào khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh hồng, quả phát triển bình thường.',
      'solutions': 'Duy trì chăm sóc và cắt tỉa hợp lý',
    },
    'Pepper,_bell___Bacterial_spot': {
      'overview': 'Bệnh đốm vi khuẩn ớt chuông do Xanthomonas campestris.',
      'cause': 'Vi khuẩn lây qua hạt giống và nước tưới bị nhiễm.',
      'signs': 'Đốm nước nhỏ trên lá, vết loét trên quả.',
      'solutions':
          'Dùng hạt giống sạch bệnh,Phun thuốc đồng,Luân canh cây trồng',
    },
    'Pepper,_bell___healthy': {
      'overview': 'Cây ớt chuông khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh đậm, quả phát triển đều.',
      'solutions': 'Tiếp tục chăm sóc và bón phân hợp lý',
    },
    'Potato___Early_blight': {
      'overview': 'Bệnh sương mai sớm khoai tây do nấm Alternaria solani.',
      'cause': 'Nấm tấn công lá già trước, phát triển mạnh khi nóng ẩm.',
      'signs': 'Đốm đồng tâm hình bia bắn trên lá, bắt đầu từ lá dưới.',
      'solutions':
          'Luân canh 2-3 năm,Phun fungicide,Loại bỏ tàn dư cây bệnh,Tưới gốc không tưới lá',
    },
    'Potato___Late_blight': {
      'overview': 'Bệnh sương mai muộn khoai tây do Phytophthora infestans.',
      'cause': 'Nấm lây lan cực nhanh trong điều kiện ẩm mát (10-20°C).',
      'signs': 'Vết bệnh nâu đen ướt trên lá, mặt dưới có lớp mốc trắng.',
      'solutions':
          'Phun fungicide ngay khi phát hiện,Tiêu hủy cây bệnh,Trồng giống kháng,Thoát nước tốt',
    },
    'Potato___healthy': {
      'overview': 'Cây khoai tây khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, thân cứng cáp.',
      'solutions': 'Duy trì bón phân và phòng bệnh định kỳ',
    },
    'Raspberry___healthy': {
      'overview': 'Cây mâm xôi khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh, quả phát triển tốt.',
      'solutions': 'Tiếp tục chăm sóc thường xuyên',
    },
    'Soybean___healthy': {
      'overview': 'Cây đậu nành khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, cây phát triển bình thường.',
      'solutions': 'Duy trì chế độ chăm sóc',
    },
    'Squash___Powdery_mildew': {
      'overview': 'Bệnh phấn trắng bí do nhiều loài nấm thuộc bộ Erysiphales.',
      'cause': 'Nấm phát triển mạnh trong điều kiện ấm, ẩm, thiếu nắng.',
      'signs': 'Lớp bột trắng phủ trên lá, lá vàng và khô dần.',
      'solutions':
          'Phun dung dịch baking soda,Phun thuốc trừ nấm lưu huỳnh,Tăng khoảng cách cây,Tưới gốc',
    },
    'Strawberry___Leaf_scorch': {
      'overview': 'Bệnh cháy lá dâu tây do nấm Diplocarpon earlianum.',
      'cause': 'Nấm lây lan qua nước mưa bắn từ đất lên lá.',
      'signs': 'Đốm tím đỏ nhỏ trên lá, sau đó lá cháy khô.',
      'solutions':
          'Loại bỏ lá bệnh,Phun fungicide,Tưới nhỏ giọt thay tưới phun,Trồng giống kháng',
    },
    'Strawberry___healthy': {
      'overview': 'Cây dâu tây khỏe mạnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh bóng, quả phát triển tốt.',
      'solutions': 'Duy trì chăm sóc và phòng bệnh',
    },
    'Tomato___Bacterial_spot': {
      'overview': 'Bệnh đốm vi khuẩn cà chua do Xanthomonas vesicatoria.',
      'cause': 'Vi khuẩn lây qua hạt giống nhiễm và nước tưới.',
      'signs': 'Đốm nước nhỏ trên lá và quả, lá vàng rụng.',
      'solutions':
          'Dùng hạt giống sạch bệnh,Phun thuốc đồng,Luân canh cây trồng,Tránh tưới phun',
    },
    'Tomato___Early_blight': {
      'overview': 'Bệnh sương mai sớm cà chua do nấm Alternaria solani.',
      'cause': 'Nấm sống trong đất và tàn dư, tấn công lá dưới trước.',
      'signs': 'Đốm đồng tâm hình vòng tròn trên lá già.',
      'solutions':
          'Luân canh cây trồng,Phun fungicide phòng ngừa,Che phủ đất,Cắt bỏ lá bệnh',
    },
    'Tomato___Late_blight': {
      'overview': 'Bệnh sương mai muộn cà chua do Phytophthora infestans.',
      'cause': 'Nấm lây lan nhanh trong điều kiện ẩm mát.',
      'signs': 'Vết bệnh nâu đen ướt, mốc trắng mặt dưới lá.',
      'solutions':
          'Tiêu hủy cây bệnh,Phun fungicide,Trồng giống kháng,Thoát nước tốt',
    },
    'Tomato___Leaf_Mold': {
      'overview': 'Bệnh mốc lá cà chua do nấm Passalora fulva.',
      'cause': 'Nấm phát triển mạnh ở độ ẩm >85% và nhiệt độ 22-25°C.',
      'signs': 'Đốm vàng nhạt mặt trên lá, mốc xám mặt dưới.',
      'solutions':
          'Giảm độ ẩm nhà kính,Tăng thông gió,Phun fungicide,Trồng giống kháng',
    },
    'Tomato___Septoria_leaf_spot': {
      'overview': 'Bệnh đốm lá Septoria cà chua do nấm Septoria lycopersici.',
      'cause': 'Nấm sống trên tàn dư, lây qua nước mưa bắn.',
      'signs': 'Đốm nhỏ tròn, tâm xám, viền nâu đen, có chấm đen nhỏ.',
      'solutions':
          'Loại bỏ lá bệnh dưới gốc,Phun fungicide,Che phủ đất,Luân canh',
    },
    'Tomato___Spider_mites Two-spotted_spider_mite': {
      'overview': 'Nhện đỏ hai chấm (Tetranychus urticae) hại cà chua.',
      'cause': 'Nhện phát triển mạnh trong điều kiện nóng khô.',
      'signs': 'Lá có chấm vàng nhỏ, mặt dưới có tơ nhện, lá khô cháy.',
      'solutions':
          'Phun nước áp lực cao lên mặt dưới lá,Sử dụng thiên địch,Phun thuốc trừ nhện,Tăng độ ẩm',
    },
    'Tomato___Target_Spot': {
      'overview': 'Bệnh đốm bia cà chua do nấm Corynespora cassiicola.',
      'cause': 'Nấm phát triển trong điều kiện ấm ẩm.',
      'signs': 'Đốm đồng tâm nâu với các vòng tròn đồng tâm rõ trên lá.',
      'solutions':
          'Phun fungicide,Cắt tỉa tạo thông thoáng,Luân canh,Thu gom lá bệnh',
    },
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus': {
      'overview': 'Virus xoăn vàng lá cà chua (TYLCV) do bọ phấn trắng truyền.',
      'cause': 'Virus lây truyền qua bọ phấn trắng Bemisia tabaci.',
      'signs': 'Lá vàng cuộn lên, cây lùn, ít đậu quả.',
      'solutions':
          'Diệt bọ phấn trắng,Sử dụng lưới chắn côn trùng,Nhổ bỏ cây bệnh,Trồng giống kháng',
    },
    'Tomato___Tomato_mosaic_virus': {
      'overview': 'Bệnh khảm cà chua do Tomato mosaic virus (ToMV).',
      'cause': 'Virus lây qua tiếp xúc cơ học, hạt giống, dụng cụ.',
      'signs': 'Lá khảm vàng xanh, biến dạng, quả chín không đều.',
      'solutions':
          'Nhổ bỏ cây bệnh,Khử trùng dụng cụ,Rửa tay khi làm việc,Trồng giống kháng',
    },
    'Tomato___healthy': {
      'overview': 'Cây cà chua khỏe mạnh, không phát hiện bệnh.',
      'cause': 'Không có.',
      'signs': 'Lá xanh tươi, quả phát triển đều.',
      'solutions': 'Tiếp tục chăm sóc và phòng bệnh định kỳ',
    },
  };
}
