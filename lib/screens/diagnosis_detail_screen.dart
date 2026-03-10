import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diagnosis_record.dart';
import '../theme/design_system.dart';

class DiagnosisDetailScreen extends StatelessWidget {
  final DiagnosisRecord record;

  const DiagnosisDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: FarmColors.surface,
        iconTheme: const IconThemeData(color: FarmColors.textPrimary),
        title: Text("Chi tiết chẩn đoán", style: FarmTextStyles.heading3),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                    child: _buildImage(),
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
                        Text(
                          "Độ tin cậy: ${record.confidence}%",
                          style: FarmTextStyles.labelSmall.copyWith(
                            color: record.confidence > 80
                                ? FarmColors.success
                                : FarmColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection("Tổng quan", record.overview),
            _buildSection("Nguyên nhân", record.cause,
                titleColor: FarmColors.error),
            _buildSection("Dấu hiệu", record.signs),
            Text("Giải pháp", style: FarmTextStyles.heading3),
            const SizedBox(height: 8),
            ...record.solutions.map((s) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: FarmColors.primary)),
                    Expanded(
                        child: Text(s,
                            style: FarmTextStyles.bodyLarge
                                .copyWith(height: 1.4))),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
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
        errorBuilder: (context, error, stackTrace) => Container(
          width: 70,
          height: 70,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[200],
      child: const Icon(Icons.eco_rounded, color: Colors.grey),
    );
  }

  Widget _buildSection(String title, String content,
      {Color titleColor = FarmColors.textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: FarmTextStyles.heading3.copyWith(color: titleColor)),
        const SizedBox(height: 8),
        Text(content, style: FarmTextStyles.bodyLarge),
        const SizedBox(height: 20),
      ],
    );
  }
}
