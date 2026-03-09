import 'package:flutter/material.dart';
import '../models/diagnosis_record.dart';
import '../theme/design_system.dart';
import 'diagnosis_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DiagnosisRecord> records = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final List<Map<String, dynamic>> datasetFake = [
      {
        "image":
            "https://vietplants.com/wp-content/uploads/2024/09/Benh-heo-ru-Panama.png",
        "date": "20/1/2026",
        "time": "10:30",
        "tree_name": "Cây chuối",
        "disease_type": "Bệnh khảm lá",
        "confidence_level": 92,
        "overview":
            "Bệnh khảm lá là tình trạng lá xuất hiện các vết đốm vàng xanh xen kẽ...",
        "solutions": ["Tiêu hủy cây bệnh", "Diệt rệp muội"]
      },
      {
        "image":
            "https://vietplants.com/wp-content/uploads/2024/09/Benh-heo-ru-Moko.png",
        "date": "21/1/2026",
        "time": "15:45",
        "tree_name": "Cây lúa",
        "disease_type": "Bệnh đạo ôn",
        "confidence_level": 85,
        "overview": "Bệnh gây hại nặng nề nhất...",
        "solutions": ["Giữ mực nước", "Bón phân"]
      },
      {
        "image":
            "https://vietplants.com/wp-content/uploads/2024/09/Benh-Sigatoka-tren-chuoi.png",
        "date": "26/1/2026",
        "time": "09:20",
        "tree_name": "Cây cà chua",
        "disease_type": "Héo xanh",
        "confidence_level": 65,
        "overview": "Héo đột ngột...",
        "solutions": ["Nhổ bỏ"]
      },
    ];

    records = datasetFake.map((item) {
      return DiagnosisRecord(
        date: "${item['date']} | ${item['time']}",
        plantName: item['tree_name'],
        diseaseName: item['disease_type'],
        confidence: item['confidence_level'],
        imageUrl: item['image'],
        overview: item['overview'] ?? "Chưa có thông tin",
        cause: item['cause'] ?? "Chưa rõ nguyên nhân",
        signs: item['signs'] ?? "Không có dấu hiệu",
        solutions: List<String>.from(item['solutions'] ?? []),
      );
    }).toList();
  }

  void _sortByName() {
    setState(() {
      records.sort((a, b) => a.plantName.compareTo(b.plantName));
    });
  }

  void _sortByConfidence() {
    setState(() {
      records.sort((a, b) => b.confidence.compareTo(a.confidence));
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: FarmColors.surface,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Lọc kết quả", style: FarmTextStyles.heading3),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.sort_by_alpha, color: FarmColors.primary),
                title:
                    Text("Theo tên cây (A-Z)", style: FarmTextStyles.bodyLarge),
                onTap: () {
                  _sortByName();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.trending_up, color: FarmColors.primary),
                title: Text("Độ tin cậy cao nhất",
                    style: FarmTextStyles.bodyLarge),
                onTap: () {
                  _sortByConfidence();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Note: This widget is used inside HomeScreen which provides the Scaffold/AppBar.
    // We only provide the body content.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${records.length} bản ghi",
                style: FarmTextStyles.labelSmall,
              ),
              TextButton.icon(
                onPressed: () => _showFilterBottomSheet(context),
                icon: const Icon(Icons.filter_list,
                    size: 18, color: FarmColors.textSecondary),
                label: Text("Bộ lọc", style: FarmTextStyles.labelSmall),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            itemCount: records.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildHistoryCard(context, records[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, DiagnosisRecord record) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DiagnosisDetailScreen(record: record)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FarmColors.surface,
          borderRadius: FarmStyles.cardRadius,
          boxShadow: FarmStyles.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                record.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.date, style: FarmTextStyles.labelSmall),
                  const SizedBox(height: 4),
                  Text("Tên cây: ${record.plantName}",
                      style: FarmTextStyles.button
                          .copyWith(color: FarmColors.textPrimary)),
                  Text("Loại bệnh: ${record.diseaseName}",
                      style: FarmTextStyles.bodyMedium),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${record.confidence}%",
                      style: FarmTextStyles.labelSmall.copyWith(
                        color: record.confidence > 80
                            ? FarmColors.success
                            : FarmColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
