import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/ruby_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController;

  const SettingsScreen({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final isDark = settingsController.isDarkMode;

        return Scaffold(
          backgroundColor: RubyTheme.background(context),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              slivers: [
                // 1. Creative Sliver App Bar
                SliverAppBar(
                  expandedHeight: 60, // Standard height
                  floating: true,
                  pinned: true,
                  backgroundColor: RubyTheme.background(context),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: RubyTheme.textPrimary(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                  title: Text(
                    'الإعدادات',
                    style: RubyTheme.heading2(context).copyWith(
                      color: RubyTheme.textPrimary(context),
                      fontSize: 18,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),

                        // SECTION 1: WALLPAPER GALLERY (Hero Section)
                        // _buildSectionLabel(context, 'خلفياتك'),
                        // SizedBox(height: 16),
                        _buildHeroWallpaperGallery(context),

                        SizedBox(height: 32),

                        // SECTION 2: OPACITY SLIDER (Creative)
                        if (settingsController.wallpaperType == 'image') ...[
                          // _buildSectionLabel(context, 'الشفافية'),
                          // SizedBox(height: 16),
                          _buildCreativeOpacitySlider(context),
                          SizedBox(height: 32),
                        ],

                        // SECTION 3: CONTROLS GRID (Dark Mode & Notifications)
                        _buildSectionLabel(context, 'تفضيلات التطبيق'),
                        // SizedBox(height: 16),
                        _buildControlGrid(context, isDark: isDark),

                        SizedBox(height: 48), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: RubyTheme.bodyMedium(context).copyWith(
        color: RubyTheme.textSecondary(context),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  // --- 1. HERO WALLPAPER GALLERY ---
  Widget _buildHeroWallpaperGallery(BuildContext context) {
    // Softer, eye-friendly pastel colors
    final safeColors = [
      {'name': 'Charcoal', 'color': 0xFF37474F}, // Softer dark
      {'name': 'Midnight', 'color': 0xFF263238},
      {'name': 'Lavender', 'color': 0xFF9575CD}, // Softer purple
      {'name': 'Sage', 'color': 0xFFA5D6A7}, // Softer green
      {'name': 'Cream', 'color': 0xFFFFF9C4},
      {'name': 'Cloud', 'color': 0xFFECEFF1},
    ];

    return SizedBox(
      height: 180, // Tall cards for "Hero" feel
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          // ... (rest of children)
          // A. Pattern Option (Asset) - DEFAULT FIRST
          _buildHeroCard(
            context,
            isSelected:
                settingsController.wallpaperType == 'image' &&
                settingsController.isAssetWallpaper,
            onTap: () => settingsController.setWallpaperImage(
              'assets/pattern.jpg',
              isAsset: true,
            ),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pattern.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الافتراضي',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // B. Recent Wallpapers (History)
          ...settingsController.recentWallpapers.map((path) {
            return _buildRecentWallpaperCard(context, path);
          }),

          // C. Custom Image Option (Picker) - APPENDED
          _buildHeroCard(
            context,
            isSelected: false,
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                await settingsController.setWallpaperImage(image.path);
              }
            },
            child: Container(
              color: RubyTheme.surfaceVariant(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: RubyTheme.primary(context),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'جديدة',
                    style: RubyTheme.bodyMedium(context).copyWith(
                      color: RubyTheme.primary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // D. Safe Theme Colors
          ...safeColors.map((colorData) {
            final colorValue = colorData['color'] as int;
            final color = Color(colorValue);
            final isSelected =
                settingsController.wallpaperType == 'color' &&
                settingsController.backgroundColor.value == colorValue;

            return _buildHeroCard(
              context,
              isSelected: isSelected,
              onTap: () => settingsController.setBackgroundColor(color),
              child: Container(color: color),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentWallpaperCard(BuildContext context, String path) {
    // Check if this path is currently selected
    final isSelected =
        settingsController.wallpaperType == 'image' &&
        settingsController.wallpaperPath == path &&
        !settingsController.isAssetWallpaper;

    // Use a file image provider
    // Note: We need dart:io for File, but we can't import it in web easily.
    // Assuming mobile env based on previous context.
    // We'll use Image.asset for simplicity if path starts with assets, else we might need Image.file
    // But since we are strictly in a managed env, let's assume we can use generic logic or Image.asset/network is not enough.
    // Actually, `Image.file(File(path))` is needed.
    // I need to import dart:io.

    // Since I can't easily add imports in this replacement block without risking breaking the top file,
    // I will use a helper that doesn't rely on File directly if possible, or assume Image.file is available if I add the import.
    // Wait, I can't add import here easily.
    // I'll skip File import for now and assume the `DecorationImage` approach works if I use `AssetImage` or `NetworkImage`.
    // Ah, local file path needs `FileImage`.
    // I will modify the top of the file in a separate step to add `import 'dart:io';`.

    // For now I'll just use a placeholder logic or try to use a specialized widget if available.
    // I will use `Image.network` as a fallback or similar? No.
    // REQUIRED: `import 'dart:io';` at the top. I will do that first in next step.

    return _buildHeroCard(
      context,
      isSelected: isSelected,
      onTap: () => settingsController.setWallpaperImage(path),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: RubyTheme.surfaceVariant(context),
                child: Icon(
                  Icons.broken_image_rounded,
                  color: RubyTheme.textSecondary(context),
                ),
              );
            },
          ),
          if (isSelected)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  color: RubyTheme.pureWhite,
                  size: 32,
                ),
              ),
            ),
          // Delete Icon
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => settingsController.removeWallpaper(path),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut, // Safe curve (no overshoot)
        width: 120, // Mobile-friendly width
        margin: EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: RubyTheme.primary(context), width: 3)
              : Border.all(color: Colors.transparent, width: 0),
          // FIX: Match shadow lists for safe interpolation
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? RubyTheme.primary(context).withOpacity(
                      0.2,
                    ) // Softer opacity
                  : Colors.transparent,
              blurRadius: isSelected ? 8 : 0, // Softer blur (was 12)
              offset: isSelected ? Offset(0, 4) : Offset.zero,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Inner radius
          child: child,
        ),
      ),
    );
  }

  // --- 2. CONTROL GRID ---
  Widget _buildControlGrid(BuildContext context, {required bool isDark}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4, // Rectangular cards
      children: [
        // Dark Mode Toggle
        _buildGridControlCard(
          context,
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          label: isDark ? 'نايت موود' : 'لايت موود',
          isActive: true, // Always active as a toggle
          activeColor: isDark
              ? RubyTheme.surface(context)
              : Colors.amber.withOpacity(0.1),
          iconColor: isDark ? RubyTheme.pureWhite : Colors.amber,
          onTap: () => settingsController.toggleDarkMode(!isDark),
        ),

        // Notifications Toggle
        _buildGridControlCard(
          context,
          icon: settingsController.enableNotifications
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          label: 'الإشعارات',
          isActive: settingsController.enableNotifications,
          activeColor: RubyTheme.surface(context),
          iconColor: settingsController.enableNotifications
              ? RubyTheme.primary(context)
              : RubyTheme.textSecondary(context),
          onTap: () => settingsController.toggleNotifications(
            !settingsController.enableNotifications,
          ),
        ),
      ],
    );
  }

  Widget _buildGridControlCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? RubyTheme.surface(context)
              : RubyTheme.surface(context).withOpacity(0.5),
          borderRadius: BorderRadius.circular(28),
          border: isActive
              ? Border.all(
                  color: RubyTheme.primary(context).withOpacity(0.1),
                  width: 1,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: RubyTheme.bodyMedium(context).copyWith(
                fontWeight: FontWeight.bold,
                color: RubyTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. CREATIVE OPACITY SLIDER ---
  Widget _buildCreativeOpacitySlider(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'وضوح الخلفية',
                style: RubyTheme.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RubyTheme.primary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(settingsController.wallpaperOpacity * 100).toInt()}%',
                  style: TextStyle(
                    color: RubyTheme.primary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: RubyTheme.primary(context),
              inactiveTrackColor: RubyTheme.surfaceVariant(
                context,
              ), // Lighter track
              thumbColor: RubyTheme.primary(context),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayColor: RubyTheme.primary(context).withOpacity(0.1),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: settingsController.wallpaperOpacity,
              onChanged: (value) =>
                  settingsController.setWallpaperOpacity(value),
            ),
          ),
        ],
      ),
    );
  }
}
