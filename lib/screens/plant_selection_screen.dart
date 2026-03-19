import 'package:flutter/material.dart';
import '../services/plant_disease_service.dart';
import '../theme/design_system.dart';
import 'diagnose_screen.dart';

class PlantSelectionScreen extends StatefulWidget {
  const PlantSelectionScreen({super.key});

  @override
  State<PlantSelectionScreen> createState() => _PlantSelectionScreenState();
}

class _PlantSelectionScreenState extends State<PlantSelectionScreen> {
  late Future<List<String>> _uniquePlantsFuture;

  @override
  void initState() {
    super.initState();
    _uniquePlantsFuture = PlantDiseaseService().getUniquePlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Text('Chọn loại cây', style: FarmTextStyles.heading3),
        backgroundColor: FarmColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: FarmColors.textPrimary),
      ),
      body: FutureBuilder<List<String>>(
        future: _uniquePlantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: FarmColors.primary));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: FarmColors.error),
                  const SizedBox(height: 16),
                  Text('Lỗi khi tải danh sách cây', style: FarmTextStyles.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _uniquePlantsFuture = PlantDiseaseService().getUniquePlants();
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: FarmColors.primary),
                    child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không tìm thấy dữ liệu cây trồng.'));
          }

          final plants = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiagnoseScreen(selectedPlant: plant),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: FarmColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: FarmStyles.cardShadow,
                    border: Border.all(color: FarmColors.surfaceVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FarmColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist_rounded,
                          size: 32,
                          color: FarmColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plant,
                        style: FarmTextStyles.button.copyWith(color: FarmColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
