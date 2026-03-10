import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diagnosis_record.dart';
import '../services/database_service.dart';
import '../theme/design_system.dart';
import 'diagnosis_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DiagnosisRecord> records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final data = await DatabaseService().getAllRecords();
    if (mounted) {
      setState(() {
        records = data;
        _isLoading = false;
      });
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64,
                color: FarmColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Chưa có lịch sử chẩn đoán', style: FarmTextStyles.bodyLarge),
            const SizedBox(height: 8),
            Text('Hãy chụp ảnh lá cây để bắt đầu!',
                style: FarmTextStyles.bodyMedium),
          ],
        ),
      );
    }

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
          child: RefreshIndicator(
            onRefresh: _loadRecords,
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
              itemCount: records.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildHistoryCard(context, records[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(DiagnosisRecord record) {
    if (record.imagePath != null && record.imagePath!.isNotEmpty) {
      final file = File(record.imagePath!);
      if (file.existsSync()) {
        return Image.file(file, width: 70, height: 70, fit: BoxFit.cover);
      }
    }
    if (record.imageUrl.isNotEmpty) {
      return Image.network(
        record.imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[200],
      child: const Icon(Icons.eco_rounded, color: Colors.grey),
    );
  }

  Widget _buildHistoryCard(BuildContext context, DiagnosisRecord record) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DiagnosisDetailScreen(record: record)),
        );
        _loadRecords(); // Refresh after returning
      },
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
              child: _buildImageWidget(record),
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
