import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';
import 'diagnose_screen.dart';
import 'history_screen.dart';
import 'market_screen.dart';
import 'settings_screen.dart';
import 'prompt_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LandingBody(),
    const DiagnoseScreen(),
    const HistoryScreen(),
    const MarketScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind the floating dock
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: Text(
          _selectedIndex == 0 ? 'FarmAI' : _getTitle(_selectedIndex),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: FarmColors.accent.withValues(alpha: 0.2),
              child: Text('JD',
                  style: FarmTextStyles.labelSmall.copyWith(
                      color: FarmColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FarmColors.background,
              FarmColors.surfaceContainer,
            ],
          ),
        ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildFloatingDock(),
    );
  }

  Widget _buildFloatingDock() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating label above dock
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart,
                  )),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _buildFloatingLabel(_selectedIndex),
            ),
            const SizedBox(height: 8),
            // Dock bar
            Container(
              decoration: BoxDecoration(
                color: FarmColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: FarmStyles.floatingShadow,
                border: Border.all(color: FarmColors.surfaceVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDockItem(0, Icons.smart_toy_rounded, 'Trang chủ'),
                  const SizedBox(width: 8),
                  _buildDockItem(1, Icons.camera_enhance_rounded, 'Chẩn đoán'),
                  const SizedBox(width: 8),
                  _buildDockItem(2, Icons.history_edu_rounded, 'Lịch sử'),
                  const SizedBox(width: 8),
                  _buildDockItem(3, Icons.storefront_rounded, 'Cửa hàng'),
                ],
              ),
            ).animate().slideY(
                begin: 1.0,
                end: 0.0,
                duration: 600.ms,
                curve: Curves.easeOutQuart),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLabel(int index) {
    final labels = ['Trang chủ', 'Chẩn đoán', 'Lịch sử', 'Cửa hàng'];
    final icons = [
      Icons.smart_toy_rounded,
      Icons.camera_enhance_rounded,
      Icons.history_edu_rounded,
      Icons.storefront_rounded,
    ];

    return Container(
      key: ValueKey<int>(index),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: FarmStyles.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FarmColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[index], color: FarmColors.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            labels[index],
            style: FarmTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? FarmColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? FarmColors.primary : FarmColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return 'Chẩn đoán AI';
      case 2:
        return 'Lịch sử';
      case 3:
        return 'Cửa hàng';
      default:
        return 'FarmAI';
    }
  }
}

class LandingBody extends StatelessWidget {
  const LandingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              "Chào buổi sáng,\n",
              style: FarmTextStyles.heading1,
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Modern Action Cards
            _buildHeroCard(
              context,
              title: "Bắt đầu Chẩn đoán",
              subtitle: "Phân tích cây trồng bằng AI",
              icon: Icons.add_a_photo_outlined,
              gradient: FarmStyles.primaryGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DiagnoseScreen()),
                );
              },
            ).animate().scale(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 20),

            _buildHeroCard(
              context,
              title: "Hỏi đáp AI",
              subtitle: "Chat với trợ lý FarmAI",
              icon: Icons.chat_bubble_outline_rounded,
              isSecondary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromptScreen()),
                );
              },
            ).animate().scale(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 28),
            // Insight Section - Material 3 Card
            Card(
              elevation: 0,
              color: FarmColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: FarmStyles.cardRadius,
                side: BorderSide(color: FarmColors.surfaceVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: FarmColors.warning, size: 22),
                        const SizedBox(width: 8),
                        Text("Thông tin trong ngày",
                            style: FarmTextStyles.heading3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Độ ẩm tối ưu cho cây Ngô. Cân nhắc giảm tưới 10% hôm nay.",
                      style: FarmTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool isSecondary = false,
    Gradient? gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FarmStyles.cardRadius,
        child: Ink(
          height: 150,
          decoration: BoxDecoration(
            gradient: gradient,
            color: isSecondary ? FarmColors.surface : null,
            borderRadius: FarmStyles.cardRadius,
            boxShadow: FarmStyles.cardShadow,
            border: isSecondary
                ? Border.all(color: FarmColors.surfaceVariant)
                : null,
          ),
          child: Stack(
            children: [
              // Decorative background circle
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: isSecondary
                      ? FarmColors.textSecondary.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSecondary
                            ? FarmColors.surfaceVariant
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSecondary ? FarmColors.primary : Colors.white,
                        size: 28,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: isSecondary
                              ? FarmTextStyles.heading2
                              : FarmTextStyles.heading2
                                  .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: isSecondary
                              ? FarmTextStyles.bodyMedium
                              : FarmTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
